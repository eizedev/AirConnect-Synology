# Packaging conventions

This repository and its sibling
[SpotConnect-Synology](https://github.com/eizedev/SpotConnect-Synology) package two
different upstream projects, but they solve the same problem in the same way: wrap
pre-built binaries from a [philippe44](https://github.com/philippe44) project into
Synology `.spk` packages, for a wide range of DSM devices, without building the binaries
themselves.

Both are maintained by the same person, so the same bug tends to exist in both, and a
fix found on real hardware for one is usually a fix for the other. Keeping the two
repositories structurally alike is what makes that transfer cheap: the SRM process-lookup
fix, the architecture matrix and the Package Center changelog text all started in one
repository and moved to the other more or less unchanged.

**The rule is "the same unless there is a documented reason to differ", not "identical".**
The two packages genuinely differ in places - SpotConnect stores reusable Spotify
credentials, AirConnect still supports a DSM 5/6 device line, and so on. Those
differences are deliberate and written down (see
[Deliberate differences](#deliberate-differences)), rather than left for a reader to
discover by diffing two repositories.

This repository is the reference for the shared parts. It is the older of the two, and
most of the shared conventions were arrived at here first.

## What is kept the same

### Repository layout

```
src/dsm7/          package sources: INFO, Makefile, scripts/, conf/, WIZARD_UIFILES/, icons
tests/             validate_spk.sh, validate_elf.py, README.md explaining both
doc/               ARCHITECTURES.md, BUILD.md, CONFIG.md, TROUBLESHOOTING.md
upstream.json      the pinned upstream release
CHANGELOG.md       packaging changes (upstream has its own)
.github/workflows/ release, upstream check, linting, security scan, housekeeping
```

### Build

- `make build` builds one architecture, `make build-all` (via `build.sh`) builds every
  architecture the `Makefile` defines. Nothing else hardcodes the architecture list -
  `build.sh` and CI derive it from the `Makefile` targets, because a second copy of that
  list has silently gone stale before.
- `INFO` is a template. `#VERSION#`, `#INFO_ARCH#` and `#INFO_FIRMWARE#` are substituted
  per architecture at build time.
- Values that `INFO` already holds are not repeated in the `Makefile`: the package name,
  the packaging repository URL and the upstream repository URL are read from `package`,
  `distributor_url` and `maintainer_url`. More generally, names, URLs and versions
  belong in one place and are derived from there.
- The bundled upstream `LICENSE` and `CHANGELOG` are fetched from the pinned upstream
  tag, never from upstream's default branch, so what ships in the package matches the
  binaries that ship with it.

### Versioning and releases

- A package version is `<upstream version>-<build date>`, for example
  `1.11.3-20260919`. The git tag is the same string.
- A tag ending in `-pre`, `-rc*`, `-beta*` or `-alpha*` is published as a GitHub
  pre-release. Release badges, `/releases/latest` and package-source feeds skip those.
- Releases ship every architecture as a separate `.spk` plus a `SHA256SUMS` file.
- Upstream is pinned in `upstream.json` (version, tag, asset name, SHA256). The release
  workflow re-downloads the asset and refuses to build if the checksum does not match.

### Traceability

- [Conventional Commits](https://www.conventionalcommits.org/) with the scopes this
  repository uses (`dsm7`, `dsm6`, `ci`, `doc`, `pkg`).
- `CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), with
  one addition: a `### Internal` subsection for repository, CI and documentation changes
  that do not affect the installed package.
- The first sentence of each entry in the newest release section becomes the "What's New"
  text Package Center shows for an update, so entries lead with what changes for the
  person installing the package. `src/dsm7/info_changelog.sh` generates that text from
  `CHANGELOG.md` and upstream's `CHANGELOG`. **That script is meant to be a
  byte-identical copy in both repositories** - everything project-specific is passed to
  it as an argument. Change it in one place, then copy it over.
- Entries link the issue or discussion a change came from, so a report stays findable
  years later.
- Behaviour that was measured on real hardware says so, including device model, DSM/SRM
  version and the measured value. Assumptions about Synology platforms have repeatedly
  turned out to be wrong.

### Checks

- Shell scripts target portable POSIX `sh`, not bash: they run under BusyBox on some
  devices. `shellcheck -s sh` is the baseline.
- `tests/validate_spk.sh` checks a built `.spk` (structure, mandatory `INFO` fields, no
  leftover placeholders, payload and lifecycle scripts, icons). `tests/validate_elf.py`
  checks that each bundled binary is actually built for the architecture the package
  claims.
- CI on every push and pull request: build and validate all architectures, super-linter,
  and a tokenless Semgrep scan. Weekly, an upstream check opens a version-bump pull
  request when a new upstream release appears; merging it tags and publishes.
- Third-party GitHub Actions are pinned to a commit SHA, with a Dependabot cooldown
  before adopting a newly published version.

## Deliberate differences

SpotConnect-Synology documents where it departs from these conventions and why. Its
reasons so far come from the packages being genuinely different - reusable Spotify
credentials must not be stored in a shared folder or passed on a command line, its two
binaries take different arguments for the same letters, and it has no DSM 5/6 device
line to support because it has no existing users on one.

This repository, in turn, carries things SpotConnect-Synology does not need, notably the
legacy `src/dsm` tree for DSM 5/6.

## When changing something shared

1. Change it here first where practical, since this repository is the reference.
2. Port it to the sibling repository rather than letting the two drift, and say so in
   both changelogs.
3. If it should not be ported, record that as a deliberate difference with the reason,
   in the repository that differs.
