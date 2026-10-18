#!/usr/bin/env bash
# Run this entire helper in one fakeroot session to preserve numeric ownership.
set -Eeuo pipefail
[[ $# == 4 ]] || { echo 'Usage: build-rootfs.sh INPUT ROOT OVERLAY OUTPUT' >&2; exit 2; }
input=$1 root=$2 overlay=$3 output=$4
[[ ! -e $root && ! -e $output ]] || { echo 'Use a fresh build directory.' >&2; exit 1; }
unsquashfs -no-progress -d "$root" "$input"
cp -a "$overlay/." "$root/"
# Added files belong to root in the live filesystem, regardless of build user.
chown -R 0:0 "$root/opt/kairo" "$root/usr/local" "$root/etc/motd"
mksquashfs "$root" "$output" -noappend -comp zstd -Xcompression-level 15 -b 1M -processors 4 -no-progress
