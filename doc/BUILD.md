# Building from source

Most users don't need this - the [releases](https://github.com/eizedev/AirConnect-Synology/releases)
page already has pre-built packages for every supported architecture, built automatically
by GitHub Actions on every release. Build it yourself only if you want a different
[AirConnect](https://github.com/philippe44/AirConnect) version than what's pinned, or
you're changing the packaging scripts themselves.

## Requirements

- `make`
- `shellcheck`
- a clone of this repository

## 1. Set the AirConnect version to package

```bash
export RELEASE_VERSION=1.11.3
```

## 2. Download the AirConnect binaries

Grab the release matching `RELEASE_VERSION` from
[philippe44/AirConnect releases](https://github.com/philippe44/AirConnect/releases) and
extract it into `src/dsm7/bin`:

```bash
wget https://github.com/philippe44/AirConnect/releases/download/${RELEASE_VERSION}/AirConnect-${RELEASE_VERSION}.zip -O src/dsm7/bin/AirConnect.zip
cd src/dsm7/bin
unzip AirConnect.zip
cd ../../..
```

## 3. (Optional) Run shellcheck

```bash
cd src/dsm7
make shellcheck
```

## 4. Build

For one architecture:

```bash
cd src/dsm7
ARCH=x86_64 make clean build
```

Possible values for `ARCH`: `arm arm-static armv5 armv5-static armv6 armv6-static aarch64
aarch64-static x86 x86-static x86_64 x86_64-static powerpc powerpc-static`

For every architecture at once:

```bash
cd src/dsm7
make clean build-all
```

Built packages land in `dist/`.

## The legacy DSM 5/6 package

`src/dsm` builds the same way, but is a frozen package line - see
[Older DSM 5/6 devices](ARCHITECTURES.md#older-dsm-56-devices) for why, and use
`ARCH=x86-64` (hyphen, not underscore) there instead of `x86_64`.
