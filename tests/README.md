# tests/

Automated checks for the AirConnect-Synology packaging pipeline. There was no
test coverage at all before this - CI only ran `shellcheck` and an `ls`. That
gap is exactly how issue #107 happened: a corrupted binary from a broken
unzip step shipped in a release and nobody noticed until users reported it.

| Script            | What it catches                                                                                                                                                                        | Would have caught #107?                                                         |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `validate_elf.py` | Corrupted/wrong-architecture binaries: ELF magic, machine type, static/dynamic, min-kernel note, glibc symbol versions                                                                 | Yes - a non-ELF file fails immediately                                          |
| `validate_spk.sh` | Malformed `.spk` structure, missing/invalid `INFO` fields, unsubstituted `#VERSION#`-style placeholders, missing/non-executable payload binaries or lifecycle scripts, corrupted icons | Yes, at the package-structure level (validate_elf.py catches the binary itself) |
| `qemu_smoke.sh`   | Binaries that can't actually execute on their target architecture/kernel                                                                                                               | planned, not yet written                                                        |
| `scripts/`        | Installer script bugs (postinst/postupgrade/start-stop-status) against a mocked `SYNOPKG_*` environment                                                                                | planned, not yet written                                                        |

## validate_elf.py

Pure standard library, no dependencies - parses the ELF header, program
headers (`PT_INTERP`, `PT_NOTE`/`NT_GNU_ABI_TAG`), and `.gnu.version_r`
directly, matching what `readelf -d`/`readelf -n` would show, without
depending on `readelf` being present in the CI image.

```sh
python3 tests/validate_elf.py --arch x86_64 target/airupnp target/aircast
```

`--arch` must be one of the `ARCH=` values used by `src/dsm7/Makefile`
(`arm`, `arm-static`, `armv5`, `armv5-static`, `armv6`, `armv6-static`,
`aarch64`, `aarch64-static`, `x86`, `x86-static`, `x86_64`, `x86_64-static`,
`powerpc`, `powerpc-static`).

Hard failures (non-zero exit): missing ELF magic, wrong machine type for the
requested architecture, static/dynamic mismatch, and - only where directly
confirmed by measurement, see the comment in the script - a float-ABI
mismatch on `arm`/`armv5`.

Everything else (minimum kernel version, glibc symbol versions referenced,
interpreter path) is reported but does not fail the run by itself, and is
**purely descriptive** - the point of measuring it here is to know what
we're shipping, not to predict compatibility. Real-world testing (see the
project's `synology-kernel-compat` memory) found that the ELF note's
declared minimum kernel does not reliably predict whether a binary runs on
a given device: the runtime check it used to trigger was removed from
glibc around 2022, and whether it still fires depends on the target
device's own patched glibc build, which varies by DSM patch level, not
just by platform/kernel. **Do not build a static pass/fail compatibility
matrix or an `arch=` exclusion list from this data alone** - the project's
actual compatibility approach is a runtime probe at install time
(`scripts/preinst` actually attempting to run the binary), because that is
the only thing that reflects the real, per-device, per-patch-level
situation.

Findings recorded from real measurements so far are tracked separately from
this repository, not in the code itself - this readme stays about what the
tooling does, not about specific version numbers, which go stale.

## validate_spk.sh

Pure POSIX `sh` (checked with `dash -n`; no bash-only features), no
dependencies beyond `tar`, `od`, `grep`, `sed` - all present on the CI image
already used for `shellcheck`. Extracts a `.spk` into a temp dir and checks:

- required top-level members present (`INFO`, `package.tgz`, `LICENSE`,
  `scripts/`, `conf/`, `WIZARD_UIFILES/`, both icon PNGs; `CHANGELOG`
  missing is a warning, not a hard fail, since a network hiccup fetching it
  from upstream shouldn't block a release the way a corrupted binary should)
- `INFO` has every mandatory field (`package`, `version`, `description`,
  `arch`, `maintainer`, `os_min_ver`) non-empty, and **no leftover
  `#VERSION#`/`#INFO_ARCH#`/`#INFO_FIRMWARE#` placeholders** - this is the
  check that would catch a silently-failed `sed` substitution in the
  Makefile, a realistic failure mode nothing previously tested for
- `package.tgz` extracts and contains `airupnp`/`aircast`, both executable
- every lifecycle script in `scripts/` is present, executable, and starts
  with a shebang line
- both `PACKAGE_ICON*.PNG` have a valid PNG magic number; dimension changes
  from the current 64x64/256x256 are flagged as a warning (not a fail -
  it's informational, we don't have a confirmed source for what Synology
  actually requires here, see `tests/validate_elf.py`'s comment style on
  not asserting unverified specs as fact)

```sh
sh tests/validate_spk.sh dist/AirConnect-dsm7-x86_64-1.11.3-20260916.spk
```

**Real finding from running this against the current 1.8.3 release**: all
seven lifecycle scripts under `src/dsm7/scripts/` are tracked in Git as
mode `100644` (non-executable) instead of `100755` - confirmed with
`git ls-files -s src/dsm7/scripts/` - and the built `.spk` inherits that.
Flagged for the maintainer to decide on rather than fixed here, since it
touches tracked file modes rather than adding new files. Verified with a
synthetic clean copy (`chmod +x` applied before re-tarring) that the
validator reports a clean `OK` once the scripts are executable, so this
isn't a false positive in the check itself.

**On real DSM hardware this is confirmed harmless** (DS415+/DS923+, DSM
7.1.1/7.4.1, `synopkg install`: `preinst`/`postinst` both ran with exit
code 0 despite the missing +x bit) - DSM clearly invokes these scripts via
an interpreter rather than executing them directly. **On SRM (RT2600ac)
this is unconfirmed and currently looks different**: the one real install
attempt that "succeeded" there never actually populated `airconnect.conf`
or the log file, meaning `postinst` likely did not run to completion - and
a second attempt failed the install outright. Not root-caused yet (see the
project's `start-stop-status-ps-bug` memory for the full, still-open
finding); until it is, **do not assume the exec-bit finding's "harmless"
conclusion applies to SRM/routers** - treat it as DSM-specific.
