# Fastfetch

ARCHNEMESIS system information with Luffy artwork on the left and boxed Hardware, Software, and Uptime / Age / DateTime sections on the right. Existing module colors and icons are preserved.

Run `ff` or `fastfetch` in Kitty. No additional image tools are needed: `kitty-direct` lets the terminal read the static PNG directly.

## Files

- `config.jsonc`: modules, colors, logo size, and spacing.
- `luffy.png`: the active artwork, stored locally so it does not depend on Downloads.
- `os-age.sh`: calculates installation age from the pacman log; displays Unknown when no installation entry is available.
- `ascii.txt` and `archnemesis.txt`: optional text artwork; unused by the active configuration.

## Appearance

The logo occupies 38 columns by 15 rows. Padding is five rows above, four columns on the left, and seven columns between the artwork and information. Adjust `logo.width`, `logo.height`, and `logo.padding` in `config.jsonc` to change these values.

Use a sufficiently wide terminal to fit the artwork and information side by side. Nerd Font icons require a compatible terminal font.

For a terminal without Kitty graphics support, run:

```sh
fastfetch --logo-type builtin --logo arch
```

Changes apply on the next invocation; no shell or compositor restart is required.
