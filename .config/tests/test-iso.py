#!/usr/bin/env python3
"""Validate ISO payload isolation and Archinstall integration without disks or root."""
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from types import ModuleType, SimpleNamespace
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]


class IsoTest(unittest.TestCase):
    def test_stage_excludes_machine_state_and_build_outputs(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'payload'
            subprocess.run([sys.executable, str(ROOT / 'iso/stage-payload.py'), str(ROOT), str(target)], check=True)
            self.assertTrue((target / 'install.sh').is_file())
            self.assertTrue((target / 'iso/overlay/usr/local/bin/archinstall').is_file())
            for name in ('.git', '.build', 'out', 'site/node_modules', 'site/dist',
                         '.config/hypr/current-wallpaper', '.config/hyprlock/hyprlock.conf'):
                self.assertFalse((target / name).exists(), name)

    def test_plugin_stages_kairo_but_never_the_live_wrapper(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary)
            modules = {name: ModuleType(name) for name in ('archinstall', 'archinstall.lib', 'archinstall.lib.version')}
            modules['archinstall.lib.version'].get_version = lambda: '3.0.15'
            spec = importlib.util.spec_from_file_location('kairo_iso_plugin', ROOT / 'iso/overlay/usr/local/share/kairo/archinstall-plugin.py')
            plugin = importlib.util.module_from_spec(spec)
            with patch.dict(sys.modules, modules):
                spec.loader.exec_module(plugin)
            real_copy2 = shutil.copy2
            def copytree(source, destination, **kwargs):
                self.assertEqual(source, '/opt/kairo')
                Path(destination).mkdir(parents=True)
                real_copy2(ROOT / 'install.sh', Path(destination) / 'install.sh')
            def copy2(source, destination):
                self.assertEqual(source, '/usr/local/bin/kairo-setup')
                real_copy2(ROOT / 'iso/overlay/usr/local/bin/kairo-setup', destination)
            with patch.object(plugin.shutil, 'copytree', side_effect=copytree), patch.object(plugin.shutil, 'copy2', side_effect=copy2):
                plugin.Plugin().on_install(SimpleNamespace(target=target))
                with self.assertRaises(FileExistsError):
                    plugin.Plugin().on_install(SimpleNamespace(target=target))
                with self.assertRaises(ValueError):
                    plugin.Plugin().on_install(SimpleNamespace(target=Path('/')))
            self.assertTrue((target / 'opt/kairo/install.sh').is_file())
            self.assertTrue(os.access(target / 'usr/local/bin/kairo-setup', os.X_OK))
            self.assertFalse((target / 'usr/local/bin/archinstall').exists())
            self.assertIn('kairo-setup', (target / 'etc/profile.d/kairo.sh').read_text())

    def test_module_registry_is_unique_and_complete(self):
        rows = subprocess.check_output(['bash', str(ROOT / 'install.sh'), '--list-modules'], text=True).splitlines()
        fields = [row.split('\t') for row in rows]
        self.assertEqual(len(fields), len({row[0] for row in fields}))
        self.assertTrue(all(len(row) == 4 and row[3] in ('true', 'false') for row in fields))
        self.assertTrue({'hypr', 'sddm', 'plymouth', 'kitty-smooth'} <= {row[0] for row in fields})

    def test_efi_patch_rejects_non_image(self):
        with tempfile.TemporaryDirectory() as temporary:
            image = Path(temporary) / 'not-an-iso'
            image.write_bytes(b'no partition table')
            result = subprocess.run([sys.executable, str(ROOT / 'iso/patch-efi.py'), str(image), temporary], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(image.read_bytes(), b'no partition table')


if __name__ == '__main__':
    unittest.main()
