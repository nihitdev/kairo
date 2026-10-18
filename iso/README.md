# Arch Linux Kairo install medium

This is the official Arch installation ISO with a Kairo boot label, bundled
project sources, and a small integration with the standard `archinstall` guided
installer. It boots to the normal Arch terminal. It is not a live desktop or an
offline package repository. Internet access is required to install Arch and Kairo
packages. BIOS and UEFI boot support come from the original Arch hybrid image.

## Build

On Arch, install the build dependencies:

```sh
sudo pacman -S --needed libisoburn squashfs-tools fakeroot curl git python archlinux-keyring mtools
./iso/build.sh
```

The build runs without root. It verifies the base image's pinned SHA-256 and
Arch signature, preserves filesystem ownership with fakeroot, and replays the
original hybrid boot records with xorriso. The boot volume label stays unchanged
because Arch's kernel command line uses it to locate the live filesystem.

The base version, mirror, and checksum are in `base.env`. Set `KAIRO_BASE_ISO` to
reuse an already downloaded image of that exact version. Allow approximately
15 GB of free workspace. Sources are taken from the current working tree,
including new non-ignored files. Ignored machine state and build products are
excluded. Build directories stay under `.build/iso/` for inspection; the output
and checksum are under `out/`. Move an existing output aside before rebuilding.

## Write the USB

Identify the USB using `lsblk -o NAME,SIZE,MODEL,TRAN,MOUNTPOINTS`, and unmount
its mounted partitions. The following overwrites the **entire selected device**;
replace `/dev/sdX` with your USB device, not a partition or your system disk.

```sh
cd out
sha256sum -c kairo-arch-2026.10.01-x86_64.iso.sha256
sudo dd if=kairo-arch-2026.10.01-x86_64.iso of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

The build script never writes to a physical disk.

## Install

1. Boot the USB and select **Arch Linux Kairo install medium**.
2. Connect to the internet; use `iwctl` for Wi-Fi if needed.
3. Run `archinstall`. Review the disk layout before confirming installation.
   Create a regular user with sudo access. For a ready desktop, choose the
   Hyprland desktop profile, a greeter, and NetworkManager.
4. Reboot into the installed system and log in as your regular user.
5. Run `kairo-setup`. Select the desired modules and review package installation.
   Kairo's normal backups and rollback protections apply. Restart your session
   after configuration finishes.

The bundled wrapper invokes `/usr/bin/archinstall` with a local plugin. The
plugin copies `/opt/kairo` and `kairo-setup` into the target during base-system
installation. It does not choose, format, or mount disks itself and does not
copy the live installer wrapper onto the installed system. Run
`/usr/bin/archinstall` directly to install plain Arch without Kairo integration.

For a focused setup instead of the full selection:

```sh
kairo-setup --only hypr --only kitty --only rofi --only zsh --only starship
```

Kairo includes optional AUR dependencies and a Kitty Smooth source build. Those
can take additional time. Configure Plymouth's boot prerequisites as described
in [the Plymouth guide](../.local/share/plymouth/README.md) if you select it.

## Verification

Run the isolated tests with:

```sh
python3 .config/tests/test-iso.py
```

A real image should additionally be boot-tested in BIOS and UEFI virtual
machines. Unit tests do not prove hardware compatibility, successful disk
installation, or desktop behavior. The ISO build does not run an installation
on the host.

Upstream references: [Archiso](https://wiki.archlinux.org/title/Archiso),
[Archinstall](https://man.archlinux.org/man/archinstall.1).
