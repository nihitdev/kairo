#!/usr/bin/env python3
"""Test adaptive colors without touching the real wallpaper or Waybar process."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
try:
    from PIL import Image
except ImportError:
    Image = None

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / '.config/waybar/scripts/wallpaper-colors.py'


@unittest.skipIf(Image is None, 'Python Pillow is not installed')
class WallpaperColorsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('wallpaper_colors', SCRIPT)
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name) / 'home with spaces'
        self.home.mkdir()
        self.runtime = self.home / 'runtime'
        self.runtime.mkdir()
        self.bin = self.home / 'bin'
        self.bin.mkdir()
        self.env = dict(os.environ, HOME=str(self.home),
                        XDG_CONFIG_HOME=str(self.home / 'config'),
                        XDG_RUNTIME_DIR=str(self.runtime),
                        PATH=str(self.bin) + os.pathsep + os.environ['PATH'])
        self.image = self.home / 'blue & snowy.png'
        Image.new('RGB', (320, 180), (16, 40, 90)).save(self.image)
        self.output = self.home / 'config/waybar/colors.css'
        for command, content in {
            'hyprctl': '#!/bin/sh\nprintf \'[{"width":1366,"height":768,"focused":true}]\\n\'\n',
            'pkill': '#!/bin/sh\nprintf "%s\\n" "$*" >> "$HOME/reloads"\n',
            'ffmpeg': '#!/bin/sh\ncat "$HOME/blue & snowy.png"\n',
        }.items():
            path = self.bin / command
            path.write_text(content)
            path.chmod(0o755)

    def generate(self, *args, check=True):
        return subprocess.run([sys.executable, str(SCRIPT), *map(str, args)],
                              env=self.env, text=True, capture_output=True,
                              check=check, timeout=10)

    def test_readable_colors_and_hue_changes(self):
        m = self.module
        for rgb in [(0, 0, 0), (255, 255, 255), (120, 120, 120),
                    (16, 40, 90), (245, 210, 160)]:
            with self.subTest(background=rgb):
                palette, background = m.palette(Image.new('RGB', (320, 180), rgb))
                self.assertGreaterEqual(m.contrast(palette['wall_text'], background), 4.5)
                for key in ['wall_accent', 'wall_secondary', 'wall_muted']:
                    self.assertGreaterEqual(m.contrast(palette[key], background), 3)
        blue, _ = m.palette(Image.new('RGB', (320, 180), (10, 35, 85)))
        warm, _ = m.palette(Image.new('RGB', (320, 180), (185, 65, 20)))
        self.assertNotEqual(blue['wall_accent'], warm['wall_accent'])

    def test_atomic_generation_no_reload_and_repeat(self):
        self.generate(self.image, '--no-reload')
        css = self.output.read_text()
        self.assertIn('@define-color wall_accent', css)
        self.assertNotIn(str(self.home), css)
        before = self.output.stat().st_mtime_ns
        self.generate(self.image, '--no-reload')
        self.assertEqual(self.output.stat().st_mtime_ns, before)
        self.assertFalse((self.home / 'reloads').exists())
        self.assertEqual(list(self.output.parent.iterdir()), [self.output])

    def test_current_link_and_reload_only_on_change(self):
        current = self.home / 'config/hypr/current-wallpaper'
        current.parent.mkdir(parents=True)
        current.symlink_to(self.image)
        self.generate()
        reloads = self.home / 'reloads'
        self.assertIn('-USR2', reloads.read_text())
        self.generate()
        self.assertEqual(len(reloads.read_text().splitlines()), 1)
        Image.new('RGB', (320, 180), (185, 65, 20)).save(self.image)
        self.generate()
        self.assertEqual(len(reloads.read_text().splitlines()), 2)

    def test_invalid_image_preserves_palette(self):
        self.generate(self.image, '--no-reload')
        before = self.output.read_bytes()
        bad = self.home / 'not-an-image.png'
        bad.write_text('invalid image')
        result = self.generate(bad, '--no-reload', check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.output.read_bytes(), before)
        self.assertFalse((self.home / 'reloads').exists())

    def test_video_uses_frame_palette(self):
        video = self.home / 'test video.mp4'
        video.write_bytes(b'frame extraction mocked')
        self.generate(video, '--no-reload')
        self.assertIn('@define-color wall_accent', self.output.read_text())


if __name__ == '__main__':
    unittest.main()
