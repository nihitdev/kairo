# Security policy

## Reporting a vulnerability

Do not post vulnerability details, exploit code, credentials, or private data in
public issues or pull requests.

Email `code.nihit.dev` with the subject **Kairo security report**. Do not include
credentials or other secrets in the subject. If your mail client cannot send to
that address, open an [issue](https://github.com/nihitdev/kairo/issues) titled
**Private security contact requested**, with no technical details, affected
systems, or sensitive attachments, and wait for the maintainer to provide a
private contact method.

Once a private channel is available, include:

- The affected Kairo revision and relevant environment details.
- The affected component and a description of the impact.
- Minimal reproduction steps or a proof of concept using test data.
- Any suggested mitigation, if known.

Please allow time to investigate and coordinate disclosure. This is a
community-maintained project, with no guaranteed response time or bug bounty.

## Scope and fixes

Security reports are welcome for installer behavior, managed configurations,
download verification, and repository automation. Unexpected command execution,
destination escapes, credential exposure, and unsafe file replacement are
examples of relevant issues.

Fixes are developed on `main`. There is no separate security backport schedule
for older commits or rice branches. Include your exact revision in a report,
even if it is not the latest version.

Third-party applications and downloaded components have their own security
processes. If Kairo's integration contributes to the problem, include that in
the report. Keep upstream license and attribution information intact.

## Testing safely

Test only on systems and data you own or have permission to assess. Use a
disposable home directory or virtual machine for installer reproduction, and
avoid real credentials. A temporary `HOME` does not isolate system package
changes; `--install-packages` can still modify the host.

Use `--dry-run` to inspect a deployment plan before making changes. Report any
dry-run writes or unexpected package operations as bugs.
