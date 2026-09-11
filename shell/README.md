# Kairo Shell prototype

This local prototype is a Quickshell layer for the Kairo desktop. It currently provides
the first working surface: a lightweight top bar with Kairo branding,
workspace indicators, and a clock.

Run it from a checkout with:

```sh
quickshell -p shell/shell.qml
```

This prototype is not the payload deployed by the installer's `kairo-shell`
module. That module downloads a pinned release of the separate Kairo Shell
project, which includes the daemon, launcher, settings, and desktop surfaces.
See the [installation guide](../README.md#kairo-shell).
