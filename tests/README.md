# tests/

Automated checks for the AirConnect-Synology packaging pipeline. There was no
test coverage at all before this - CI only ran `shellcheck` and an `ls`. That
gap is exactly how issue #107 happened: a corrupted binary from a broken
unzip step shipped in a release and nobody noticed until users reported it.

| Script | What it catches | Would have caught #107? |
|---|---|---|
| `validate_elf.py` | Corrupted/wrong-architecture binaries: ELF magic, machine type, static/dynamic, min-kernel note, glibc symbol versions | Yes - a non-ELF file fails immediately |
| `validate_spk.sh` | Malformed `.spk` package structure, missing/invalid `INFO` fields | planned, not yet written |
| `qemu_smoke.sh` | Binaries that can't actually execute on their target architecture/kernel | planned, not yet written |
| `scripts/` | Installer script bugs (postinst/postupgrade/start-stop-status) against a mocked `SYNOPKG_*` environment | planned, not yet written |

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
interpreter path) is reported but does not fail the run by itself. That data
feeds the compatibility matrix described in the project plan (Phase 2/6) -
the point of measuring it here is to know what we're shipping, not to assert
an expected value we'd just be guessing at.

Findings recorded from real measurements so far live in the project's
`synology-kernel-compat` memory entry, not in this repo (see the project
CLAUDE.md/memory for how that's organized) - this README stays about what
the tooling does, not about specific version numbers, which go stale.
