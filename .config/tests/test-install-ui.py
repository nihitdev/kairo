#!/usr/bin/env python3
"""Exercise menu frames without running the installer or changing live configs."""
import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
UI = ROOT / '.config/scripts/install-ui.sh'
INSTALLER = (ROOT / 'install.sh').read_text()
ARRAYS = '\n'.join(re.findall(
    r'declare -a (?:module|profile)_(?:names|labels|categories)=\([\s\S]*?\)',
    INSTALLER,
))
ANSI = re.compile(r'\x1b\[[0-?]*[ -/]*[@-~]')


def render(rows, columns, group='module', resize=False, source=None):
    script = (source if source is not None else UI.read_text()) + '\n' + ARRAYS + '\n'
    script += f'''
terminal_rows={rows} terminal_columns={columns}
tput() {{ case "$1" in lines) echo "$terminal_rows" ;; cols) echo "$terminal_columns" ;; esac; }}
declare -a choices=()
for name in "${{{group}_names[@]}}"; do choices+=(false); done
step=0
ui_read_key() {{
    ((step++)) || true
    case "$step" in
        1) UI_KEY=all ;;
        2) UI_KEY=none ;;
        3) UI_KEY=space ;;
        4) UI_KEY=end ;;
        5) UI_KEY=page_up ;;
        6) UI_KEY=page_down ;;
        7) UI_KEY=home ;;
        8) UI_KEY=down ;;
        9) UI_KEY=space ;;
        10) UI_KEY=up ;;
        11) UI_KEY=enter ;;
    esac
    {'((step == 5)) && { terminal_rows=24; terminal_columns=40; }' if resize else ':'}
    return 0
}}
ui_select_modules {group}_names {group}_labels {group}_categories choices
printf '\\nRESULT %s %s\\n' "${{choices[0]}}" "${{choices[1]}}"
'''
    return subprocess.run(['bash', '-eu'], input=script, text=True,
                          capture_output=True, check=True, timeout=10).stdout


class MenuTest(unittest.TestCase):
    def check_frames(self, output, rows, columns, resize=False):
        frames = re.findall(r'\x1b\[\?2026h(.*?)\x1b\[\?2026l', output, re.S)
        self.assertEqual(len(frames), 11)
        for index, frame in enumerate(frames):
            height, width = (24, 40) if resize and index >= 5 else (rows, columns)
            text = ANSI.sub('', frame)
            self.assertLess(text.count('\n'), height, f'frame {index} scrolls at {height} rows')
            for line in text.splitlines():
                self.assertLessEqual(len(line), width, f'frame {index} wraps: {line!r}')
            self.assertTrue(frame.startswith('\x1b[H\x1b[J'), 'old frame was not erased')
            self.assertEqual(text.count('Choose your modules'), 1)
            self.assertEqual(text.count('Enter'), 1)
            self.assertEqual(text.count('›'), 1)
        self.assertIn('RESULT true true', output)

    def test_navigation_and_selection(self):
        for group in ('module', 'profile'):
            for rows, columns in ((16, 32), (24, 80), (32, 80), (40, 120), (24, 40)):
                with self.subTest(group=group, rows=rows, columns=columns):
                    self.check_frames(render(rows, columns, group), rows, columns)

    def test_resize_during_navigation(self):
        self.check_frames(render(40, 120, resize=True), 40, 120, resize=True)


if __name__ == '__main__':
    unittest.main()
