#!/usr/bin/env bash
# Remaster the official hybrid ISO without mounting filesystems or requiring sudo.
set -Eeuo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo/iso/base.env"
for tool in curl sha256sum xorriso unsquashfs mksquashfs fakeroot python3 git gpg gpgv mcopy; do
    command -v "$tool" >/dev/null || { printf 'Missing build tool: %s\n' "$tool" >&2; exit 1; }
done
cache="$repo/.build/iso/cache"
mkdir -p "$cache" "$repo/out"
base=${KAIRO_BASE_ISO:-"$cache/archlinux-$ARCH_VERSION-x86_64.iso"}
if [[ ! -f $base ]]; then
    curl --fail --location --retry 3 -o "$base.partial" "$ARCH_MIRROR/$ARCH_VERSION/archlinux-$ARCH_VERSION-x86_64.iso"
    mv -- "$base.partial" "$base"
fi
printf '%s  %s\n' "$ARCH_SHA256" "$base" | sha256sum -c -
signature="$cache/archlinux-$ARCH_VERSION-x86_64.iso.sig"
curl --fail --location --retry 3 -o "$signature" "$ARCH_MIRROR/$ARCH_VERSION/archlinux-$ARCH_VERSION-x86_64.iso.sig"
gpg --batch --yes --dearmor --output "$cache/archlinux-keyring.gpg" /usr/share/pacman/keyrings/archlinux.gpg
gpgv --keyring "$cache/archlinux-keyring.gpg" "$signature" "$base"
work=$(mktemp -d "$repo/.build/iso/build.XXXXXX")
output="$repo/out/kairo-arch-$ARCH_VERSION-x86_64.iso"
[[ ! -e $output ]] || { printf 'Output already exists: %s\nMove it aside before rebuilding.\n' "$output" >&2; exit 1; }
printf 'Build directory: %s\n' "$work"
xorriso -osirrox on -indev "$base" -extract /arch/x86_64/airootfs.sfs "$work/original.sfs"
xorriso -osirrox on -indev "$base" -extract /boot/grub/loopback.cfg "$work/loopback.cfg"
xorriso -osirrox on -indev "$base" -extract /boot/syslinux "$work/syslinux"
xorriso -osirrox on -indev "$base" -extract /loader "$work/loader"
mkdir -p "$work/overlay/opt/kairo"
cp -a "$repo/iso/overlay/." "$work/overlay/"
# Copy tracked project sources and the new ISO sources; never copy HOME, .git,
# ignored per-machine state, node_modules, build outputs, or wallpaper symlinks.
python3 "$repo/iso/stage-payload.py" "$repo" "$work/overlay/opt/kairo"
python3 - "$work" <<'PY'
from pathlib import Path
import sys
work = Path(sys.argv[1])
for path in [work / 'loopback.cfg', *(work / 'syslinux').glob('*.cfg'), *(work / 'loader/entries').glob('*.conf')]:
    text = path.read_text()
    path.chmod(path.stat().st_mode | 0o200)
    path.write_text(text.replace('Arch Linux install medium', 'Arch Linux Kairo install medium'))
PY
fakeroot -- "$repo/iso/build-rootfs.sh" "$work/original.sfs" "$work/rootfs" "$work/overlay" "$work/airootfs.sfs"
(cd "$work" && sha512sum airootfs.sfs > airootfs.sha512)
# Replay the official image's El Torito and hybrid system area for BIOS/UEFI USB boot.
# Keep its volume label: the kernel uses that label to find the live filesystem.
xorriso -indev "$base" -outdev "$output" \
    -map "$work/airootfs.sfs" /arch/x86_64/airootfs.sfs \
    -map "$work/airootfs.sha512" /arch/x86_64/airootfs.sha512 \
    -map "$work/loopback.cfg" /boot/grub/loopback.cfg \
    -map "$work/syslinux" /boot/syslinux \
    -map "$work/loader" /loader \
    -rm /arch/x86_64/airootfs.sfs.cms.sig -- \
    -boot_image any replay
python3 "$repo/iso/patch-efi.py" "$output" "$work/loader/entries"
(cd "$repo/out" && sha256sum "$(basename "$output")" > "$(basename "$output").sha256")
printf 'ISO: %s\nChecksum: %s.sha256\nBuild files retained at %s\n' "$output" "$output" "$work"
