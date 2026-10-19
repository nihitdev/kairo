#!/usr/bin/env python3
import colorsys, hashlib, json, os, subprocess, sys
from pathlib import Path
from PIL import Image
H = Path.home()
CONFIG = Path(os.environ.get('XDG_CONFIG_HOME', str(H/'.config')))
CACHE = H/'.cache/wallpaper-carousel'
CACHE.mkdir(parents=True, exist_ok=True)
HISTORY = CACHE/'history.json'
STATIC = {'.png', '.jpg', '.jpeg', '.webp', '.bmp', '.avif', '.gif'}
VIDEO = {'.mp4', '.mkv', '.webm', '.mov'}
def history():
    try: return json.loads(HISTORY.read_text())
    except (OSError, ValueError): return []
def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout

def index():
    items = []
    roots = [H/'Pictures/Wallpapers']
    for root in roots:
        for p in sorted(root.rglob('*')):
            if not p.is_file() or p.suffix.lower() not in STATIC | VIDEO: continue
            vid = p.suffix.lower() in VIDEO
            key = hashlib.sha256(f'{p}:{p.stat().st_mtime_ns}'.encode()).hexdigest()
            thumb = CACHE/(key+'.jpg')
            try:
                if not thumb.exists():
                    if vid:
                        run('ffmpeg', '-v', 'error', '-y', '-i', str(p), '-frames:v', '1', '-vf', 'scale=800:-2', str(thumb))
                    else:
                        with Image.open(p) as im:
                            im.thumbnail((900, 600))
                            im.convert('RGB').save(thumb, quality=85)
                with Image.open(thumb) as im:
                    rgb = im.convert('RGB').resize((1,1)).getpixel((0,0))
                hue, sat, val = colorsys.rgb_to_hsv(*(v/255 for v in rgb))
                bucket = 'Mono' if sat < .15 else ['Red','Orange','Yellow','Green','Green','Blue','Blue','Purple','Purple','Pink','Pink','Red'][int(hue*12)%12]
                items.append(dict(name=p.name, path=str(p), url=p.as_uri(), thumb=thumb.as_uri(), video=vid, bucket=bucket))
            except (OSError, subprocess.CalledProcessError): continue
    current = CONFIG/'hypr/current-wallpaper'
    print(json.dumps(dict(items=items, history=history(), current=str(current.resolve()), monitors=json.loads(run('hyprctl','-j','monitors')))))

def apply(path, output):
    p = Path(path)
    if not p.is_file() or p.suffix.lower() not in STATIC | VIDEO: raise ValueError('Unsupported or missing wallpaper')
    if p.suffix.lower() in VIDEO:
        if output != 'all': raise ValueError('Video wallpapers currently apply to all monitors')
        subprocess.run(['pkill','-u',str(os.getuid()),'-x','mpvpaper'], capture_output=True)
        run('mpvpaper', '-f', '-p', '-o', 'no-audio loop-file=inf hwdec=auto-safe', 'ALL', str(p))
        link = CONFIG/'hypr/current-live-wallpaper'
    else:
        if subprocess.run(['pgrep','-u',str(os.getuid()),'-x','hyprpaper'], capture_output=True).returncode:
            subprocess.Popen(['hyprpaper'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
            import time
            time.sleep(.7)
        monitors = json.loads(run('hyprctl','-j','monitors'))
        targets = [m['name'] for m in monitors if output == 'all' or m['name'] == output]
        if not targets: raise ValueError('Monitor is no longer connected')
        for name in targets:
            result = run('hyprctl','hyprpaper','wallpaper',f'{name}, {p}, cover')
            if 'error' in result.lower(): raise RuntimeError(result)
        subprocess.run(['pkill','-u',str(os.getuid()),'-x','mpvpaper'], capture_output=True)
        (CONFIG/'hypr/current-live-wallpaper').unlink(missing_ok=True)
        (H/'.cache/current-wallpaper').write_text(str(p)+'\n')
        link = CONFIG/'hypr/current-wallpaper'
    temp = link.with_name(link.name+'.carousel-tmp')
    temp.unlink(missing_ok=True)
    temp.symlink_to(p)
    temp.replace(link)
    hist = [str(p)] + [v for v in history() if v != str(p)]
    tmp = HISTORY.with_suffix('.tmp')
    tmp.write_text(json.dumps(hist[:100]))
    tmp.replace(HISTORY)
    print(json.dumps({'ok':True, 'history':hist[:100]}))
if __name__ == '__main__':
    try:
        if sys.argv[1] == 'index': index()
        elif sys.argv[1] == 'apply': apply(sys.argv[2], sys.argv[3])
    except Exception as e:
        print(json.dumps({'error':str(e)}))
        sys.exit(1)
