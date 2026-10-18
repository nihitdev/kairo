#!/usr/bin/env python3
"""Exercise ISO release publishing with a mocked GitHub CLI and no network calls."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
PUBLISHER = ROOT / '.github/scripts/publish-iso-release.sh'
WORKFLOW = ROOT / '.github/workflows/build-iso.yml'


class ReleasePublisherTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.log = self.root / 'gh.log'
        self.image = self.root / 'kairo-arch-test-x86_64.iso'
        self.image.write_bytes(b'raw iso bytes')
        self.checksum = self.root / (self.image.name + '.sha256')
        self.checksum.write_text('test  ' + self.image.name + '\n')
        self.notes = self.root / 'release-notes.md'
        self.notes.write_text('Kairo ISO release notes\n')
        fake_gh = self.bin / 'gh'
        fake_gh.write_text(r'''#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$GH_TEST_LOG"
if [[ $1 == release ]]; then
    case $2 in
        view) [[ ${GH_RELEASE_EXISTS:-true} == true ]] ;;
        upload) [[ ${GH_UPLOAD_FAIL:-false} == false ]] ;;
        create|edit) exit 0 ;;
        *) exit 2 ;;
    esac
elif [[ $1 == api ]]; then
    case "$*" in
        *actions/workflows/build-iso.yml/runs*)
            if [[ ${GH_PENDING_ONCE:-false} == true && ! -e "$GH_TEST_LOG.pending" ]]; then
                touch "$GH_TEST_LOG.pending"
                printf '1\n'
            fi
            ;;
        *releases/tags/*) printf '42\n' ;;
        *releases/42/assets*)
            if [[ ${GH_ASSETS:-} == '' ]]; then
                printf '10\\told.iso\\t3\\n'
            else
                printf '%b' "$GH_ASSETS"
            fi
            ;;
        *) exit 0 ;;
    esac
else
    exit 2
fi
''')
        fake_gh.chmod(0o755)
        fake_sleep = self.bin / 'sleep'
        fake_sleep.write_text('#!/bin/sh\nexit 0\n')
        fake_sleep.chmod(0o755)
        assets = '\\t'.join(('11', self.image.name, str(self.image.stat().st_size))) + '\\n'
        assets += '\\t'.join(('12', self.checksum.name, str(self.checksum.stat().st_size))) + '\\n'
        assets += '10\\told.iso\\t3\\n'
        self.env = dict(os.environ,
                        PATH=f'{self.bin}:{os.environ["PATH"]}',
                        GH_TEST_LOG=str(self.log),
                        GITHUB_REPOSITORY='nihitdev/kairo',
                        GITHUB_SHA='0123456789abcdef0123456789abcdef01234567',
                        GITHUB_REF='refs/heads/main', GITHUB_RUN_NUMBER='9',
                        ISO_PATH=str(self.image), CHECKSUM_PATH=str(self.checksum),
                        RELEASE_NOTES_PATH=str(self.notes), RELEASE_MODE='rolling',
                        GH_ASSETS=assets)

    def run_publisher(self, success=True):
        result = subprocess.run(['bash', str(PUBLISHER)], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_rolling_release_replaces_stale_assets_and_moves_tag(self):
        result = self.run_publisher()
        calls = self.calls()
        self.assertIn('release view rolling', calls)
        self.assertIn(f'release upload rolling {self.image} {self.checksum} --clobber', calls)
        self.assertIn('api --method DELETE repos/nihitdev/kairo/releases/42/assets/10', calls)
        self.assertTrue(any(call.startswith('release edit rolling --title Kairo Rolling ISO') and '--draft=false' in call for call in calls))
        self.assertTrue(any(call.startswith('api --method PATCH repos/nihitdev/kairo/git/refs/tags/rolling') for call in calls))
        self.assertIn('Published ' + self.image.name, result.stdout)
        self.assertNotIn('split', '\n'.join(calls))

    def test_rolling_publisher_waits_for_earlier_main_runs(self):
        self.env['GH_PENDING_ONCE'] = 'true'
        result = self.run_publisher()
        requests = [call for call in self.calls() if 'actions/workflows/build-iso.yml/runs' in call]
        self.assertEqual(len(requests), 2)
        self.assertTrue(any('.run_number < 9' in call and '\\\"' not in call for call in requests))
        self.assertIn('Waiting for earlier main ISO run', result.stdout)

    def test_first_rolling_release_is_created_once_as_draft_then_published(self):
        self.env['GH_RELEASE_EXISTS'] = 'false'
        self.env['GH_ASSETS'] = '\\t'.join(('11', self.image.name, str(self.image.stat().st_size))) + '\\n'
        self.env['GH_ASSETS'] += '\\t'.join(('12', self.checksum.name, str(self.checksum.stat().st_size))) + '\\n'
        calls = self.calls()
        self.run_publisher()
        calls = self.calls()
        self.assertEqual(sum(call.startswith('release create rolling ') for call in calls), 1)
        create = next(call for call in calls if call.startswith('release create rolling '))
        self.assertIn('--draft', create)
        self.assertIn('--target ' + self.env['GITHUB_SHA'], create)
        self.assertTrue(any('--draft=false' in call for call in calls if call.startswith('release edit rolling ')))

    def test_versioned_release_path_is_retained_and_does_not_touch_rolling(self):
        self.env['RELEASE_MODE'] = 'versioned'
        self.env['RELEASE_TAG'] = 'iso-v1.2.3'
        result = self.run_publisher()
        calls = self.calls()
        self.assertIn(f'release upload iso-v1.2.3 {self.image} {self.checksum} --clobber', calls)
        self.assertTrue(any(call.startswith('release edit iso-v1.2.3 ') for call in calls))
        self.assertFalse(any('rolling' in call for call in calls))
        self.assertIn('Published ' + self.image.name, result.stdout)

    def test_asset_at_github_limit_fails_before_any_release_change(self):
        with self.image.open('wb') as image:
            image.truncate(2 * 1024 * 1024 * 1024)
        self.run_publisher(success=False)
        self.assertEqual(self.calls(), [])

    def test_upload_failure_never_prunes_or_publishes(self):
        self.env['GH_UPLOAD_FAIL'] = 'true'
        self.run_publisher(success=False)
        calls = self.calls()
        self.assertTrue(any(call.startswith('release upload rolling ') for call in calls))
        self.assertFalse(any('assets/10' in call for call in calls))
        self.assertFalse(any(call.startswith('release edit rolling ') for call in calls))
        self.assertFalse(any('git/refs/tags/rolling' in call for call in calls))

    def test_workflow_contract_and_shell_commands(self):
        try:
            import yaml
        except ImportError:
            self.skipTest('PyYAML is unavailable; CI installs yamllint and validates YAML there')
        workflow = yaml.safe_load(WORKFLOW.read_text())
        triggers = workflow.get(True, workflow.get('on'))
        self.assertIn('main', triggers['push']['branches'])
        self.assertIn('iso-v*', triggers['push']['tags'])
        self.assertIn('workflow_dispatch', triggers)
        self.assertEqual(workflow['permissions']['contents'], 'read')
        job = workflow['jobs']['build']
        self.assertEqual(job['permissions']['contents'], 'write')
        self.assertFalse(workflow['concurrency']['cancel-in-progress'])
        steps = job['steps']
        self.assertFalse(any('upload-artifact' in step.get('uses', '') for step in steps))
        self.assertTrue(any(step.get('run') == 'bash .github/scripts/publish-iso-release.sh'
                            and step.get('env', {}).get('RELEASE_MODE') == 'rolling' for step in steps))
        self.assertTrue(any(step.get('if', '').startswith("startsWith(github.ref, 'refs/tags/iso-v')")
                            and step.get('env', {}).get('RELEASE_MODE') == 'versioned' for step in steps))
        for step in steps:
            script = step.get('run')
            if script:
                parsed = subprocess.run(['bash', '-n'], input=script, text=True, capture_output=True)
                self.assertEqual(parsed.returncode, 0, step.get('name', 'workflow run block') + parsed.stderr)
        self.assertFalse(any('upload-artifact' in step.get('uses', '') for step in steps))
        publisher = (ROOT / '.github/scripts/publish-iso-release.sh').read_text()
        self.assertIn('GitHub Release assets must be smaller than 2 GiB', publisher)
        self.assertNotIn('split --', publisher)
        self.assertNotIn('.zip', publisher)


if __name__ == '__main__':
    unittest.main()
