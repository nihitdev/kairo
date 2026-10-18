#!/usr/bin/env python3
"""Ensure generated build inputs can never enter the live ISO payload."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class StagePayloadTest(unittest.TestCase):
    def test_excludes_tracked_build_dirs_even_without_ignore_rules(self):
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary) / 'repo'
            target = Path(temporary) / 'payload'
            repo.mkdir()
            for relative, content in (
                ('.build/cache/archlinux.iso', b'large base image'),
                ('out/previous.iso', b'old generated image'),
                ('iso/keep.txt', b'ISO source'),
            ):
                path = repo / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(content)
            subprocess.run(['git', '-C', str(repo), 'init', '-q'], check=True)
            subprocess.run(['git', '-C', str(repo), 'config', 'user.email', 'test@example.invalid'], check=True)
            subprocess.run(['git', '-C', str(repo), 'config', 'user.name', 'ISO test'], check=True)
            subprocess.run(['git', '-C', str(repo), 'add', '-f', '.build', 'out', 'iso/keep.txt'], check=True)
            subprocess.run(['git', '-C', str(repo), 'commit', '-qm', 'fixture'], check=True)
            subprocess.run([sys.executable, str(ROOT / 'iso/stage-payload.py'), str(repo), str(target)], check=True)

            self.assertTrue((target / 'iso/keep.txt').is_file())
            self.assertFalse((target / '.build').exists())
            self.assertFalse((target / 'out').exists())


if __name__ == '__main__':
    unittest.main()
