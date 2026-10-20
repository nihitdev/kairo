#!/usr/bin/env python3
"""Generate Waybar colors on wallpaper changes; no background watcher needed."""
import argparse
import colorsys
import fcntl
from io import BytesIO
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

from PIL import Image, ImageOps, ImageStat

CONFIG = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config'))
VIDEO = {'.mp4', '.webm', '.mkv', '.mov'}


def wallpaper_image(path):
    if path.suffix.lower() in VIDEO:
        frame = subprocess.run(
            ['ffmpeg', '-v', 'error', '-i', str(path), '-frames:v', '1',
             '-vf', 'scale=640:-2', '-f', 'image2pipe', '-vcodec', 'png', '-'],
            capture_output=True, check=True, timeout=15)
        with Image.open(BytesIO(frame.stdout)) as image:
            return image.convert('RGB')
    with Image.open(path) as image:
        return ImageOps.exif_transpose(image).convert('RGB')


def luminance(rgb):
    def linear(value):
        value /= 255
        return value / 12.92 if value <= .04045 else ((value + .055) / 1.055) ** 2.4
    return sum(weight * linear(value) for weight, value in zip((.2126, .7152, .0722), rgb))


def contrast(a, b):
    bright, dark = sorted((luminance(a), luminance(b)), reverse=True)
    return (bright + .05) / (dark + .05)


def color(hue, saturation, lightness):
    return tuple(round(channel * 255) for channel in colorsys.hls_to_rgb(hue % 1, lightness, saturation))


def readable(hue, saturation, lightness, background, minimum=4.5):
    rgb = color(hue, saturation, lightness)
    # Choose the better contrast direction rather than assuming every image is dark.
    light = contrast((255, 255, 255), background) >= contrast((0, 0, 0), background)
    for _ in range(100):
        if contrast(rgb, background) >= minimum:
            return rgb
        lightness = min(1, lightness + .01) if light else max(0, lightness - .01)
        rgb = color(hue, saturation, lightness)
    return rgb


def palette(image, aspect=16 / 9):
    sample = image.copy()
    sample.thumbnail((160, 160))
    quantized = sample.quantize(colors=12)
    colors = quantized.getpalette()
    candidates = []
    for count, index in quantized.getcolors():
        rgb = tuple(colors[index * 3:index * 3 + 3])
        hue, saturation, value = colorsys.rgb_to_hsv(*(channel / 255 for channel in rgb))
        candidates.append((count * (.12 + saturation ** 1.4) * (.35 + value), hue, saturation))
    _, hue, saturation = max(candidates)
    saturation = min(.72, max(.20, saturation))
    secondary = (hue + .07) % 1
    for _, candidate, sat in sorted(candidates, reverse=True):
        separation = min(abs(candidate - hue), 1 - abs(candidate - hue))
        if .08 < separation < .45 and sat > .18:
            secondary = candidate
            break
    # Hyprpaper uses cover: sample the strip behind the bar after the same crop.
    covered = ImageOps.fit(image, (640, max(1, round(640 / aspect))))
    strip = covered.crop((0, 0, covered.width, max(1, round(covered.height * .075))))
    background = tuple(round(channel) for channel in ImageStat.Stat(strip).mean)
    light_text = contrast((255, 255, 255), background) >= contrast((0, 0, 0), background)
    lightness = .82 if light_text else .24
    return {
        'wall_text': readable(hue, .15, .94 if light_text else .12, background),
        'wall_accent': readable(hue, saturation, lightness, background, 3.0),
        'wall_secondary': readable(secondary, min(.55, saturation), lightness, background, 3.0),
        'wall_muted': readable(hue, .12, .68 if light_text else .30, background, 3.0),
        'wall_hover_rgb': color(hue, saturation, .76 if light_text else .27),
        'wall_tooltip_bg_rgb': color(hue, .25, .075),
        'wall_tooltip_text': color(hue, .12, .94),
        'wall_urgent': (148, 64, 78),
        'wall_on_urgent': (255, 245, 245),
        'wall_critical': readable(.035, .80, .70 if light_text else .32, background),
    }, background


def stylesheet(colors):
    lines = ['/* Generated from the selected wallpaper by wallpaper-colors.py. */']
    for name, rgb in colors.items():
        if name.endswith('_rgb'):
            alpha = .16 if name == 'wall_hover_rgb' else .94
            name = name.removesuffix('_rgb')
            value = f'rgba({rgb[0]}, {rgb[1]}, {rgb[2]}, {alpha})'
        else:
            value = '#' + ''.join(f'{channel:02x}' for channel in rgb)
        lines.append(f'@define-color {name} {value};')
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('wallpaper', nargs='?', type=Path)
    parser.add_argument('--output', type=Path, default=CONFIG / 'waybar/colors.css')
    parser.add_argument('--no-reload', action='store_true')
    args = parser.parse_args()
    path = args.wallpaper
    if path is None:
        path = CONFIG / 'hypr/current-live-wallpaper'
        if not path.is_file():
            path = CONFIG / 'hypr/current-wallpaper'
    path = path.expanduser().resolve(strict=True)
    aspect = 16 / 9
    try:
        monitors = json.loads(subprocess.check_output(['hyprctl', '-j', 'monitors'], timeout=3))
        monitor = next((m for m in monitors if m.get('focused')), monitors[0])
        aspect = monitor['width'] / monitor['height']
    except (OSError, subprocess.SubprocessError, ValueError, KeyError, IndexError):
        pass
    args.output.parent.mkdir(parents=True, exist_ok=True)
    runtime = Path(os.environ.get('XDG_RUNTIME_DIR', str(args.output.parent)))
    with (runtime / 'waybar-wallpaper-colors.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        colors, _ = palette(wallpaper_image(path), aspect)
        css = stylesheet(colors)
        if args.output.exists() and args.output.read_text() == css:
            return
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(mode='w', dir=args.output.parent, delete=False) as output:
                temporary = Path(output.name)
                output.write(css)
            temporary.replace(args.output)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
        if not args.no_reload:
            subprocess.run(['pkill', '-USR2', '-u', str(os.getuid()), '-x', 'waybar'],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f'Waybar wallpaper palette: {error}', file=sys.stderr)
        sys.exit(1)
