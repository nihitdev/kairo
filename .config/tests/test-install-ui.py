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
ui_select_modules {group}_names {group}_labels {group}_categories choices {'"Choose development tools"' if group == 'profile' else ''}
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
            self.assertEqual(text.count('Choose '), 1)
            self.assertEqual(text.count('Enter'), 1)
            self.assertEqual(text.count('›'), 1)
            self.assertEqual(text.count('Page '), 1)
            self.assertIn('Q', text)
            anchor = re.search(r'\x1b\[(\d+);1H', frame)
            self.assertIsNotNone(anchor)
            footer_row = int(anchor[1])
            self.assertEqual(footer_row, height - 4)
            self.assertLess(ANSI.sub('', frame[:anchor.start()]).count('\n'), footer_row)
            self.assertEqual(footer_row + frame[anchor.end():].count('\n'), height)
            active = next(line for line in frame.splitlines() if '›' in line)
            self.assertIn('\x1b[48;5;236m', active)
            self.assertEqual(len(ANSI.sub('', active)), width - 2)
        first = ANSI.sub('', frames[0])
        all_selected = ANSI.sub('', frames[1])
        total = re.search(r'0 / (\d+) selected', first)[1]
        self.assertIn(f'{total} / {total} selected', all_selected)
        self.assertIn(f'0 / {total} selected', ANSI.sub('', frames[2]))
        self.assertIn('RESULT true true', output)

    def test_navigation_and_selection(self):
        for group in ('module', 'profile'):
            for rows, columns in ((16, 32), (24, 80), (32, 80), (40, 120), (24, 40)):
                with self.subTest(group=group, rows=rows, columns=columns):
                    self.check_frames(render(rows, columns, group), rows, columns)

    def test_resize_during_navigation(self):
        self.check_frames(render(40, 120, resize=True), 40, 120, resize=True)


class ShellChoiceTest(unittest.TestCase):
    def choose(self, keys, initial='keep'):
        script = UI.read_text() + "\n" + f"""
tput() {{ case "$1" in lines) echo 16 ;; cols) echo 32 ;; esac; }}
keys=({' '.join(keys)})
step=0
ui_read_key() {{ UI_KEY=${{keys[step]}}; step=$((step + 1)); }}
choice={initial}
status=0
ui_select_default_shell choice || status=$?
printf '\nRESULT %s %s\n' "$choice" "$status"
"""
        return subprocess.run(['bash', '-eu'], input=script, text=True,
                              capture_output=True, check=True, timeout=5).stdout

    def test_default_and_each_shell(self):
        for index, shell in enumerate(('keep', 'bash', 'zsh', 'fish', 'nushell')):
            output = self.choose(['down'] * index + ['enter'])
            self.assertIn(f'RESULT {shell} 0', output)

    def test_cli_preselection_and_cancel(self):
        self.assertIn('RESULT fish 0', self.choose(['enter'], 'fish'))
        self.assertIn('RESULT zsh 1', self.choose(['down', 'quit'], 'zsh'))
        self.assertIn('RESULT keep 0', self.choose(['end', 'home', 'enter']))


class ReviewTest(unittest.TestCase):
    def test_wait_ignores_navigation(self):
        script = UI.read_text() + """
keys=(down space ignore enter)
step=0
ui_read_key() { UI_KEY=${keys[step]}; step=$((step + 1)); }
ui_wait_for_enter
printf 'READS %s' "$step"
"""
        result = subprocess.run(['bash', '-eu'], input=script, text=True,
                                capture_output=True, check=True, timeout=5)
        self.assertIn('READS 4', result.stdout)

    def test_review_scroll_and_cancel(self):
        script = UI.read_text() + """
tput() { case "$1" in lines) echo 16 ;; cols) echo 32 ;; esac; }
keys=(end home quit)
step=0
ui_read_key() { UI_KEY=${keys[step]}; step=$((step + 1)); }
text=''
for ((i=0; i<40; i++)); do text+="review line $i"$'\\n'; done
status=0
ui_review "$text" || status=$?
printf 'RESULT %s' "$status"
"""
        result = subprocess.run(['bash', '-eu'], input=script, text=True,
                                capture_output=True, check=True, timeout=5)
        frames = result.stdout.split('\x1b[2J\x1b[H')[1:]
        self.assertEqual(len(frames), 3)
        self.assertIn('review line 0', frames[0])
        self.assertNotIn('review line 39', frames[0])
        self.assertIn('review line 39', frames[1])
        self.assertIn('review line 0', frames[2])
        self.assertIn('RESULT 1', result.stdout)

    def test_swaync_label_and_review(self):
        self.assertIn('SwayNC + battery', ANSI.sub('', render(24, 80)))
        result = subprocess.run(['bash', '-eu'], input=UI.read_text() +
                                '\nui_swaync_summary', text=True, capture_output=True,
                                check=True, timeout=5)
        self.assertIn('10-second timeouts', result.stdout)
        self.assertIn('one watcher', result.stdout)

    def test_module_labels_are_plain_text(self):
        function = re.search(r'module_label\(\) \{.*?\n\}', INSTALLER, re.S)[0]
        result = subprocess.run(['bash', '-eu'], input=ARRAYS + '\n' + function +
                                '\nmodule_label hypr', text=True, capture_output=True,
                                check=True, timeout=5)
        self.assertEqual(result.stdout, 'Hyprland')


if __name__ == '__main__':
    unittest.main()
