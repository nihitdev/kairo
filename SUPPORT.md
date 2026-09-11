# Getting help

Start with the [README](README.md), `./install.sh --help`, and a dry-run of the
module you are trying to install:

```sh
./install.sh --dry-run --only wezterm
```

For installation questions, configuration problems, and reproducible bugs,
[search existing issues](https://github.com/nihitdev/kairo/issues) and open an
issue if the problem has not been covered.

Include:

- Your distribution, architecture, and relevant application versions.
- The Kairo revision from `git rev-parse --short HEAD`.
- The command you ran and which modules you selected.
- Expected behavior, actual behavior, and minimal reproduction steps.
- Relevant error output, with secrets and private details removed.

Do not attach your entire home directory or configuration archive. Remove tokens,
passwords, SSH keys, private hostnames, and personal details from logs and screenshots.

Use [SECURITY.md](SECURITY.md) for suspected vulnerabilities. Community help is
provided as time permits; there is no guaranteed response time.

Kairo Shell has a separate codebase. For shell runtime bugs that also occur
outside this installer, use the
[Kairo Shell issue tracker](https://github.com/nihitdev/kairo-shell/issues).
Report package selection, deployment, and Hyprland integration problems here.
