# Building from source

Most users don't need this - the [releases](https://github.com/eizedev/AirConnect-Synology/releases)
page already has pre-built packages for every supported architecture, built automatically
by GitHub Actions on every release. Build it yourself only if you want a different
[AirConnect](https://github.com/philippe44/AirConnect) version than what's pinned, or
you're changing the packaging scripts themselves.

## Requirements

- `make`
- `shellcheck`
- `jq`, for reading the pinned release out of `upstream.json` in step 1
- a clone of this repository

## 1. Download the pinned AirConnect binaries

Which upstream release this package wraps is pinned in
[`upstream.json`](../upstream.json): `tag` is the release the files come from, `version`
is the version the package is named after, and `sha256` is the checksum CI verifies the
download against. The build reads that file, so there is nothing to set.

Grab that release from
[philippe44/AirConnect releases](https://github.com/philippe44/AirConnect/releases) and
extract it into `src/dsm7/bin`:

```bash
TAG=$(jq -r .tag upstream.json)
ASSET=$(jq -r .asset upstream.json)
wget "https://github.com/philippe44/AirConnect/releases/download/${TAG}/${ASSET}" -O src/dsm7/bin/AirConnect.zip
cd src/dsm7/bin
unzip AirConnect.zip
cd ../../..
```

To package an upstream release that is not pinned, put its binaries in `src/dsm7/bin`
and set `RELEASE_VERSION` to the version you want the package named after - it overrides
the version from `upstream.json`.

## 2. (Optional) Run shellcheck

```bash
cd src/dsm7
make shellcheck
```

## 3. Build

For one architecture:

```bash
cd src/dsm7
ARCH=x86_64 make clean build
```

Possible values for `ARCH`: `arm arm-static armv5 armv5-static aarch64
aarch64-static x86 x86-static x86_64 x86_64-static powerpc powerpc-static`

For every architecture at once:

```bash
cd src/dsm7
make clean build-all
```

Built packages land in `dist/`.

## Adding or removing an architecture

`src/dsm7/Makefile` is the single source of truth for which architectures
exist - each one is a `.PHONY` target that sets `INFO_ARCH` (the Synology
platform codes it declares as compatible):

```make
.PHONY: x86_64
x86_64:
	$(eval export INFO_ARCH=x86_64 x64 cedarview ...)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true
```

`build.sh` (its `ARCH_LIST`) and `.github/workflows/release.yml` (its package
validation step) both **derive** their list of architectures from the
Makefile automatically, rather than keeping their own copy:

```bash
awk '/^\.PHONY: /{t=$2} /INFO_ARCH=/{print t}' Makefile
```

This walks the file line by line: whenever it sees a `.PHONY: <name>` line,
it remembers `<name>`; whenever it then sees that target's `INFO_ARCH=`
line, it prints the remembered name. Non-architecture `.PHONY` targets
(`build`, `clean`, `clean-dist`, `clean-bin`, `build-all`, `shellcheck`) have
no `INFO_ARCH=` line, so they're never matched - no separate exclude-list to
maintain.

`release.yml` additionally counts how many `.spk` files `make build-all`
actually produced and compares that against this same derived list's
length, so a build that silently skips an architecture fails CI instead of
just validating whatever happened to show up.

**Why this matters**: a hand-copied second list goes stale. When the `armv6`
target was removed from the Makefile
([#222](https://github.com/eizedev/AirConnect-Synology/issues/222)), a copy
of the list in `release.yml` still expected an `armv6` package and failed CI
looking for a file that was never going to exist. Adding or removing an
architecture means editing the Makefile and nothing else - `build.sh` and
`release.yml` pick it up automatically. You'll still want to update this
file's `ARCH=` list below and
[doc/ARCHITECTURES.md](ARCHITECTURES.md#architecture-groups-dsm-7) by hand,
since those are prose for humans, not something a script parses.

## The legacy DSM 5/6 package

`src/dsm` builds the same way, but is a frozen package line - see
[Older DSM 5/6 devices](ARCHITECTURES.md#older-dsm-56-devices) for why, and use
`ARCH=x86-64` (hyphen, not underscore) there instead of `x86_64`.
