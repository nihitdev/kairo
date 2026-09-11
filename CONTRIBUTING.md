# Contributing to Kairo

Kairo combines an Arch Linux workstation installer with curated dotfiles. Small,
focused fixes, documentation improvements, and reproducible bug reports are welcome.
Please follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Before changing code

- Search existing issues and pull requests for related work.
- For a large feature or a change to installer behavior, open an issue describing
  the problem and proposed behavior before building it.
- Report suspected vulnerabilities through [SECURITY.md](SECURITY.md), rather
  than a public issue.

## Working locally

Clone your fork and create a branch for the change. Check `git status` before
editing so unrelated local changes stay out of the patch.

Preview installation before applying it:

```sh
./install.sh --dry-run --only wezterm
```

A real installation can replace your configuration. Use an isolated test home or
virtual machine when testing deployment. Keep package installation explicit with
`--install-packages`; it affects the system even when `HOME` is isolated.

## Project conventions

- Follow the surrounding style and `.editorconfig`.
- Preserve dry-run immutability, destination checks, backups, repeat-install
  behavior, and rollback when changing the installer.
- Register a new module in the installer selector, labels, defaults, package
  mapping, help, deployment, and relevant validation. Update the README and Arch
  packaging metadata as needed.
- Keep package installation opt-in and avoid introducing automatic system upgrades.
- Never include credentials, private keys, personal shell history, machine state,
  or private wallpaper files.
- Retain third-party licenses and attribution. Document vendored code in
  [VENDORED.md](VENDORED.md), and pin downloaded code to reviewed revisions.

## Validation

Run the checks relevant to your change. For installer changes:

```sh
bash -n install.sh
bash -n .config/scripts/install-ui.sh
./install.sh --dry-run
./.config/tests/test-install.sh
```

The installer tests use temporary homes and mocked operations; their remote
bootstrap checks also contact GitHub. Do not run tests with `sudo`.

For documentation and repository formats:

```sh
python3 .config/scripts/validate_repo.py
git diff --check
```

For Lua changes, syntax-check the files with `luac -p`. For website changes,
follow the [website development instructions](README.md#website-development)
and run the production build. The [CI workflow](.github/workflows/validate.yml)
defines the shared checks.

## Pull requests

Describe the problem, the resulting behavior, and how you verified it. Include
screenshots for visual changes when useful. Mention any checks you could not run
and any changes to packages or managed paths.

Keep unrelated cleanup in a separate pull request. Add regression coverage for
installer behavior that could overwrite files, break rollback, or change package
selection. Documentation-only changes do not need new automated tests.

Contributions must be compatible with the [repository license](LICENSE) and any
applicable third-party licenses. Do not change upstream license notices.
