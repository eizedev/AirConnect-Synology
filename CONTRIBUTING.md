# Contributing

Thanks for considering a contribution. This is a small, community-maintained project -
contributions are welcome, but please keep changes focused and proportional to the
problem they solve.

## Before you start

For anything more than a small fix, please open an issue or discussion first to align on
the approach before investing time in a PR - especially for anything touching the
packaging scripts (`scripts/`), the install/upgrade/uninstall wizards
(`WIZARD_UIFILES/`), or `conf/`. Bugs there can affect real installs directly.

## Building and testing locally

See [doc/BUILD.md](doc/BUILD.md) for the build steps, and [tests/README.md](tests/README.md)
for what the automated checks (`validate_spk.sh`, `validate_elf.py`) actually verify and
why each one exists.

[doc/CONVENTIONS.md](doc/CONVENTIONS.md) describes how this repository is laid out and
why - versioning, upstream pinning, changelog structure, the checks - and which of that
is deliberately kept the same as in the sibling project
[SpotConnect-Synology](https://github.com/eizedev/SpotConnect-Synology).

Shell scripts in this repo target portable POSIX `sh` (not bash) - they run under
Synology's BusyBox shell on some architectures, so bashisms will break on real hardware
even if they pass locally. `shellcheck -s sh` is the baseline check; testing on real
hardware (or at least a shell that isn't bash) before submitting is strongly encouraged
for anything touching `scripts/`.

## Commit messages

This repo generally follows [Conventional Commits](https://www.conventionalcommits.org/)
(`fix(dsm7): ...`, `docs: ...`, `ci: ...`, etc.) - not strictly enforced, but appreciated,
since it makes `CHANGELOG.md` and release notes easier to write accurately.

## Pull requests

- Keep PRs scoped to one change - easier to review, easier to revert if something's
  wrong.
- Mention what you tested and how (a real device model/DSM version if you tested on
  hardware) - see [Known limitations](README.md#known-limitations) for why real-hardware
  testing matters here more than usual: platform behavior has repeatedly turned out to
  differ from what seemed reasonable to assume.
- CI (shellcheck, markdown/YAML linting, Semgrep) runs automatically on your PR.

## Reporting bugs / requesting features

Please use the [issue templates](https://github.com/eizedev/AirConnect-Synology/issues/new/choose)
rather than a blank issue - they ask for the details (device model, package downloaded,
logs) that are almost always needed to help.

Security issues: see [SECURITY.md](SECURITY.md) - please don't open a public issue for
those.
