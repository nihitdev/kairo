# Plymouth Lone

The `lone` theme copied from the live Plymouth installation. Includes all 64
animation frames, the script, theme definition, and the original GPL-3.0 license.
Original author: Aditya Shakya (adi1090x). No other Plymouth themes are bundled.

Select **Plymouth Lone** under **System** in Kairo's module picker, or run:

```sh
./install.sh --dry-run --only plymouth
./install.sh --only plymouth --install-packages
```

This module is selected by default; deselect it in the module picker to skip it. It installs `plymouth` and Python
when package installation is requested, deploys `/usr/share/plymouth/themes/lone`,
and sets `Theme=lone` in `/etc/plymouth/plymouthd.conf`, preserving other settings.
It uses sudo for system writes and rebuilds the initramfs with `mkinitcpio -P`
when available. A temporary snapshot restores the theme and configuration on
failure; no permanent backup files are created. Staging with `--destdir` skips
sudo and initramfs generation.

On a fresh machine, configure the `plymouth` initramfs hook (before `encrypt` or
`sd-encrypt` when used) and the `quiet splash` kernel parameters using your
existing bootloader configuration. Rebuild the initramfs after changing hooks.
This module does not rewrite hooks, kernel arguments, or bootloader settings.
Systems using another initramfs generator need to rebuild it separately.

The source machine already has the Plymouth hook and `quiet splash`. Adding this
module to the repository does not alter its installed theme or boot images.

Run `bash .config/tests/test-plymouth-install.sh` for isolated installation tests.
