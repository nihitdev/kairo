#!/usr/bin/env python3
"""Exercise menu frames without running the installer or changing live configs."""
import os
import pty
import re
import select
import tempfile
import time
import shlex
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
UI = ROOT / '.config/scripts/install-ui.sh'
INSTALLER = (ROOT / 'install.sh').read_text()
ARRAYS = '\n'.join(re.findall(
    r'declare -a profile_(?:names|labels|categories)=\([\s\S]*?\)',
    INSTALLER,
))
# Consume the public registry instead of matching its implementation syntax.
MODULES = [row.split('\t') for row in subprocess.check_output(
    ['bash', str(ROOT / 'install.sh'), '--list-modules'], text=True).splitlines()]
for index, field in enumerate(('names', 'labels', 'categories')):
    ARRAYS += '\ndeclare -a module_' + field + '=(' + ' '.join(shlex.quote(row[index]) for row in MODULES) + ')'
ANSI = re.compile(r'\x1b\[[0-?]*[ -/]*[@-~]')


def paint(frame, rows, columns):
    """Read cursor-addressed frames and reject content outside the terminal."""
    cells = [[' '] * columns for _ in range(rows)]
    row = column = 0
    position = 0
    for event in re.finditer(r'\x1b\[([0-?]*)([ -/]*)([@-~])', frame):
        for char in frame[position:event.start()]:
            if char == '\n':
                row += 1
                column = 0
                continue
            if char == '\r':
                column = 0
                continue
            if not (0 <= row < rows and 0 <= column < columns):
                raise AssertionError(f'paint outside {columns}x{rows}: row={row}, column={column}')
            cells[row][column] = char
            column += 1
        if event[3] in ('H', 'f'):
            numbers = event[1].split(';')
            row = int(numbers[0] or 1) - 1
            column = int(numbers[1] or 1) - 1 if len(numbers) > 1 else 0
        position = event.end()
    # Canvas frames always end in a control sequence.
    return [''.join(line) for line in cells]


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
            lines = paint(frame, height, width)
            text = '\n'.join(lines)
            self.assertIn('K A I R O', text)
            self.assertIn('Choose ', text)
            self.assertEqual(text.count('Enter'), 1)
            self.assertEqual(text.count('›'), 1)
            self.assertEqual(text.count('Page '), 1)
            self.assertIn('Q', text)
            self.assertIn('╭', text)
            self.assertIn('╰', text)
            self.assertIn('\x1b[48;2;196;167;231m', frame)
            if width >= 90:
                self.assertIn('IN FOCUS', text)
                self.assertEqual(text.count('╭'), 2)
            else:
                self.assertEqual(text.count('╭'), 1)
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

    def test_category_navigation_and_restore_defaults(self):
        script = UI.read_text() + """
tput() { case "$1" in lines) echo 24 ;; cols) echo 100 ;; esac; }
names=(bash fish hypr)
labels=(Bash Fish Hyprland)
categories=(Shells Shells Desktop)
choices=(true false true)
keys=(none category space defaults category enter)
step=0
ui_read_key() { UI_KEY=${keys[step]}; step=$((step + 1)); }
ui_select_modules names labels categories choices
printf 'RESULT %s\n' "${choices[*]}"
"""
        result = subprocess.run(['bash', '-eu'], input=script, text=True,
                                capture_output=True, check=True, timeout=5).stdout
        frames = re.findall(r'\x1b\[\?2026h(.*?)\x1b\[\?2026l', result, re.S)
        active = [next(line for line in paint(frame, 24, 100) if '›' in line)
                  for frame in frames]
        self.assertIn('Hyprland', active[2])
        self.assertIn('Bash', active[5])
        self.assertIn('RESULT true false true', result)
        self.assertIn('Quickshell', '\n'.join(paint(frames[2], 24, 100)))

    def test_resize_during_navigation(self):
        self.check_frames(render(40, 120, resize=True), 40, 120, resize=True)


class ShellChoiceTest(unittest.TestCase):
    def choose(self, keys, initial='keep', menu='ui_select_default_shell'):
        script = UI.read_text() + "\n" + f"""
tput() {{ case "$1" in lines) echo 16 ;; cols) echo 32 ;; esac; }}
keys=({' '.join(keys)})
step=0
ui_read_key() {{ UI_KEY=${{keys[step]}}; step=$((step + 1)); }}
choice={initial}
status=0
{menu} choice || status=$?
printf '\nRESULT %s %s\n' "$choice" "$status"
"""
        return subprocess.run(['bash', '-eu'], input=script, text=True,
                              capture_output=True, check=True, timeout=5).stdout

    def test_default_and_each_shell(self):
        for index, shell in enumerate(('keep', 'bash', 'zsh', 'fish', 'nushell')):
            output = self.choose(['down'] * index + ['enter'])
            self.assertIn(f'RESULT {shell} 0', output)

    def test_aur_helper_selection(self):
        self.assertIn('RESULT yay 0', self.choose(['down', 'enter'], 'paru', 'ui_select_aur_helper'))
        self.assertIn('RESULT paru 0', self.choose(['enter'], 'paru', 'ui_select_aur_helper'))

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

    def test_confirmation_ignores_navigation(self):
        script = UI.read_text() + """
keys=(down ignore yes)
step=0
ui_read_key() { UI_KEY=${keys[step]}; step=$((step + 1)); }
ui_confirm 'Install packages'
printf 'READS %s' "$step"
"""
        result = subprocess.run(['bash', '-eu'], input=script, text=True,
                                capture_output=True, check=True, timeout=5)
        self.assertIn('READS 3', result.stdout)

    def test_preview_review_uses_preview_action(self):
        script = UI.read_text() + """
tput() { case "$1" in lines) echo 16 ;; cols) echo 32 ;; esac; }
ui_read_key() { UI_KEY=enter; }
ui_review 'Selected configs' 'Review installation' preview
"""
        result = subprocess.run(['bash', '-eu'], input=script, text=True,
                                capture_output=True, check=True, timeout=5)
        self.assertRegex(result.stdout, r'Enter\s+preview')
        self.assertNotIn('Enter install', result.stdout)
        self.assertIn('of 1 lines', result.stdout)

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
        frames = re.findall(r'\x1b\[\?2026h(.*?)\x1b\[\?2026l', result.stdout, re.S)
        self.assertEqual(len(frames), 3)
        self.assertIn('review line 0', frames[0])
        self.assertNotIn('review line 39', frames[0])
        self.assertIn('review line 39', frames[1])
        self.assertIn('review line 0', frames[2])
        self.assertIn('RESULT 1', result.stdout)

    def test_non_interactive_preview_in_a_terminal(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory) / 'home'
            home.mkdir()
            env = dict(os.environ, HOME=str(home), CI='false', TERM='xterm')
            for name, suffix in (('CONFIG', '.config'), ('CACHE', '.cache'),
                                 ('DATA', '.local/share'), ('STATE', '.local/state')):
                env[f'XDG_{name}_HOME'] = str(home / suffix)
            for name in ('KAIRO_BIN_DIR', 'QS_STATE_DIR'):
                env.pop(name, None)
            master, slave = pty.openpty()
            try:
                process = subprocess.Popen(
                    ['bash', str(ROOT / 'install.sh'), '--non-interactive', '--dry-run'],
                    stdin=slave, stdout=slave, stderr=slave, env=env)
                os.close(slave)
                slave = None
                output = bytearray()
                deadline = time.monotonic() + 30
                try:
                    while time.monotonic() < deadline:
                        if select.select([master], [], [], 0.1)[0]:
                            try:
                                chunk = os.read(master, 65536)
                            except OSError:
                                break
                            if not chunk:
                                break
                            output.extend(chunk)
                    process.wait(timeout=1)
                finally:
                    if process.poll() is None:
                        process.kill()
                        process.wait()
                text = output.decode(errors='replace')
                self.assertEqual(process.returncode, 0, text)
                self.assertIn('Preview complete. No changes were made.', text)
                self.assertIn('quickshell/hyprland-notifications', text)
                self.assertNotIn('Choose modules', text)
                self.assertEqual(list(home.iterdir()), [])
            finally:
                os.close(master)
                if slave is not None:
                    os.close(slave)

    def test_module_labels_are_plain_text(self):
        function = re.search(r'module_label\(\) \{.*?\n\}', INSTALLER, re.S)[0]
        result = subprocess.run(['bash', '-eu'], input=ARRAYS + '\n' + function +
                                '\nmodule_label hypr', text=True, capture_output=True,
                                check=True, timeout=5)
        self.assertEqual(result.stdout, 'Hyprland')


if __name__ == '__main__':
    unittest.main()
