#!/usr/bin/env python3
"""
Validate that AirConnect binaries are well-formed ELF executables for the
Synology architecture they are being packaged for, and report their
minimum-kernel and glibc-version requirements. Linux/ELF only - AirConnect
also ships macOS (Mach-O) binaries, but the Synology package never uses
those, so Mach-O parsing is intentionally out of scope here.

This exists because AirConnect-Synology issue #107 shipped a release where
`robinraju/release-downloader` silently corrupted the extracted binaries
during unzip: the files under bin/ were not valid ELF at all, but nothing in
CI noticed until users reported "not a valid ELF" after installing. A check
this simple - "does this file even start with the ELF magic and does its
declared machine type match what we asked the Makefile to build" - would
have caught it before release. See tests/README.md for how this fits the
overall test suite.

No third-party dependencies (must run in CI without extra pip installs).
Parses the raw ELF structures directly: ELF header, program headers
(PT_INTERP, PT_NOTE / NT_GNU_ABI_TAG), section headers and .gnu.version_r
(ElfNN_Verneed / ElfNN_Vernaux) for the GLIBC_x.y.z symbol versions actually
referenced.

Usage:
    validate_elf.py --arch <make-arch-name> <path> [<path> ...]
    validate_elf.py --arch arm target/airupnp target/aircast
    validate_elf.py --arch x86_64-static target/airupnp target/aircast \
        --json-out report.json

Exit status: 0 if every file passes the hard checks (ELF magic present,
parseable, machine type matches the requested architecture, static/dynamic
matches). Non-fatal findings (minimum kernel, glibc versions, interpreter,
float ABI) are reported but never fail the run by themselves.

IMPORTANT, learned the hard way (see the project's synology-kernel-compat
memory entry / tests/README.md): the ELF note's declared minimum kernel
does NOT reliably predict whether a binary will actually run on a given
Synology device. Real-world reports (AirConnect-Synology issues #63, #104,
confirmed by the upstream author) show failures on kernels this project
later re-tested successfully on the same kernel/glibc version - the
runtime check this note used to trigger was removed from glibc around
2022, and whether it still fires depends on the target's own patched
glibc build, not on this value. Treat min_kernel/glibc output as
descriptive diagnostic data only - never build a pass/fail compatibility
matrix or an arch= exclusion list from it alone.
"""

import argparse
import json
import struct
import sys

# EM_* constants from <elf.h>, limited to what AirConnect actually ships.
EM_MACHINE_NAMES = {
    3: "x86",
    8: "mips",
    20: "powerpc",
    40: "arm",
    62: "x86_64",
    183: "aarch64",
}

# Maps the Makefile's ARCH= value to what we expect to find in the binary.
# float_abi is only asserted where we have direct, confirmed evidence
# (see tests/README.md); other arm variants are reported but not asserted,
# because build.sh's cross-toolchain aliasing makes their default float ABI
# genuinely uncertain without measuring it - asserting a guess here would
# create a test that is wrong as often as it's right.
ARCH_EXPECTATIONS = {
    "arm": {"machine": 40, "static": False, "float_abi": "hard"},
    "arm-static": {"machine": 40, "static": True, "float_abi": "hard"},
    "armv5": {"machine": 40, "static": False, "float_abi": "soft"},
    "armv5-static": {"machine": 40, "static": True, "float_abi": "soft"},
    "aarch64": {"machine": 183, "static": False, "float_abi": None},
    "aarch64-static": {"machine": 183, "static": True, "float_abi": None},
    "x86": {"machine": 3, "static": False, "float_abi": None},
    "x86-static": {"machine": 3, "static": True, "float_abi": None},
    "x86_64": {"machine": 62, "static": False, "float_abi": None},
    "x86_64-static": {"machine": 62, "static": True, "float_abi": None},
    "powerpc": {"machine": 20, "static": False, "float_abi": None},
    "powerpc-static": {"machine": 20, "static": True, "float_abi": None},
}

PT_INTERP = 3
PT_NOTE = 4
NT_GNU_ABI_TAG = 1
SHT_GNU_VERNEED = 0x6FFFFFFE


class ElfParseError(Exception):
    """Raised when a binary doesn't look like a well-formed ELF file."""


def _read_elf_header(data):
    """Parse the fixed-size ELF header. Returns the fields the rest of
    parse_elf needs to walk the program/section header tables."""
    if len(data) < 64 or data[:4] != b"\x7fELF":
        raise ElfParseError("missing ELF magic (0x7f 'ELF') - not an ELF file")

    ei_class = data[4]  # 1 = 32-bit, 2 = 64-bit
    ei_data = data[5]  # 1 = little-endian, 2 = big-endian
    if ei_class not in (1, 2):
        raise ElfParseError(f"invalid EI_CLASS byte: {ei_class}")
    if ei_data not in (1, 2):
        raise ElfParseError(f"invalid EI_DATA byte: {ei_data}")

    endian = "<" if ei_data == 1 else ">"
    is64 = ei_class == 2

    try:
        if is64:
            _e_type, e_machine = struct.unpack_from(endian + "HH", data, 0x10)
            e_phoff, e_shoff = struct.unpack_from(endian + "QQ", data, 0x20)
            e_phentsize, e_phnum, e_shentsize, e_shnum, e_shstrndx = struct.unpack_from(
                endian + "HHHHH", data, 0x36
            )
        else:
            _e_type, e_machine = struct.unpack_from(endian + "HH", data, 0x10)
            e_phoff, e_shoff = struct.unpack_from(endian + "II", data, 0x1C)
            e_phentsize, e_phnum, e_shentsize, e_shnum, e_shstrndx = struct.unpack_from(
                endian + "HHHHH", data, 0x2A
            )
    except struct.error as exc:
        raise ElfParseError(f"truncated ELF header: {exc}") from exc

    return {
        "endian": endian,
        "is64": is64,
        "ei_data": ei_data,
        "e_machine": e_machine,
        "e_phoff": e_phoff,
        "e_phentsize": e_phentsize,
        "e_phnum": e_phnum,
        "e_shoff": e_shoff,
        "e_shentsize": e_shentsize,
        "e_shnum": e_shnum,
        "e_shstrndx": e_shstrndx,
    }


def _scan_program_headers(data, header):  # pylint: disable=too-many-locals
    """Walk the program header table for PT_INTERP (-> interp path) and
    PT_NOTE/NT_GNU_ABI_TAG (-> declared minimum kernel version). The local
    count is inherent to naming each unpacked binary field distinctly
    rather than a control-flow problem - there's nothing left to extract."""
    endian, is64 = header["endian"], header["is64"]
    interp = None
    min_kernel = None
    has_interp_segment = False

    try:
        for i in range(header["e_phnum"]):
            off = header["e_phoff"] + i * header["e_phentsize"]
            if off + 4 > len(data):
                raise ElfParseError(
                    f"program header {i} out of bounds (truncated file?)"
                )
            p_type = struct.unpack_from(endian + "I", data, off)[0]

            if is64:
                p_offset = struct.unpack_from(endian + "Q", data, off + 8)[0]
                p_filesz = struct.unpack_from(endian + "Q", data, off + 32)[0]
            else:
                p_offset = struct.unpack_from(endian + "I", data, off + 4)[0]
                p_filesz = struct.unpack_from(endian + "I", data, off + 16)[0]

            if p_type == PT_INTERP:
                has_interp_segment = True
                raw = data[p_offset : p_offset + p_filesz]
                interp = raw.split(b"\x00")[0].decode("ascii", errors="replace")

            elif p_type == PT_NOTE:
                pos, end = p_offset, p_offset + p_filesz
                while pos < end - 12 and pos + 12 <= len(data):
                    namesz, descsz, notetype = struct.unpack_from(
                        endian + "III", data, pos
                    )
                    name = data[pos + 12 : pos + 12 + namesz].split(b"\x00")[0]
                    descoff = pos + 12 + ((namesz + 3) // 4) * 4
                    if name == b"GNU" and notetype == NT_GNU_ABI_TAG and descsz >= 16:
                        _os, kmaj, kmin, ksub = struct.unpack_from(
                            endian + "IIII", data, descoff
                        )
                        min_kernel = f"{kmaj}.{kmin}.{ksub}"
                    pos = descoff + ((descsz + 3) // 4) * 4
    except (struct.error, IndexError) as exc:
        raise ElfParseError(
            f"truncated or malformed program header table: {exc}"
        ) from exc

    return interp, min_kernel, has_interp_segment


def _read_section_headers(data, header):
    """Unpack the raw section header table into (name_off, type, link,
    offset, size) tuples."""
    endian, is64 = header["endian"], header["is64"]
    sh_entries = []
    for i in range(header["e_shnum"]):
        off = header["e_shoff"] + i * header["e_shentsize"]
        if is64:
            sh_name, sh_type = struct.unpack_from(endian + "II", data, off)
            sh_link = struct.unpack_from(endian + "I", data, off + 0x28)[0]
            sh_offset, sh_size = struct.unpack_from(endian + "QQ", data, off + 0x18)
        else:
            sh_name, sh_type = struct.unpack_from(endian + "II", data, off)
            sh_link = struct.unpack_from(endian + "I", data, off + 0x18)[0]
            sh_offset, sh_size = struct.unpack_from(endian + "II", data, off + 0x10)
        sh_entries.append((sh_name, sh_type, sh_link, sh_offset, sh_size))
    return sh_entries


def _scan_glibc_versions(data, header):  # pylint: disable=too-many-locals
    """Walk the section table looking for the Verneed section, then chain
    through Verneed -> Vernaux records to collect every "GLIBC_x.y[.z]"
    version string the binary actually references.

    Informational only: any parse failure here degrades to an empty list
    rather than failing binaries that otherwise parsed fine (e.g. static
    builds, which legitimately have no version-needs section at all)."""
    glibc_versions = []
    endian = header["endian"]
    try:
        if not (
            header["e_shoff"]
            and header["e_shnum"]
            and header["e_shstrndx"] < header["e_shnum"]
        ):
            return glibc_versions

        sh_entries = _read_section_headers(data, header)
        shstr_off = sh_entries[header["e_shstrndx"]][3]

        def read_str(strtab_off, str_off):
            end = data.find(b"\x00", strtab_off + str_off)
            if end == -1:
                end = len(data)
            return data[strtab_off + str_off : end].decode("ascii", errors="replace")

        verneed_section = None
        for name_off, sh_type, sh_link, sh_off, sh_size in sh_entries:
            name = read_str(shstr_off, name_off)
            if name == ".gnu.version_r" or sh_type == SHT_GNU_VERNEED:
                verneed_section = (sh_link, sh_off, sh_size)
                break

        if verneed_section:
            link_idx, vn_off, vn_size = verneed_section
            dynstr_off = sh_entries[link_idx][3]
            pos = vn_off
            seen = set()
            while pos < vn_off + vn_size and pos not in seen:
                seen.add(pos)
                _vn_file, vn_aux, vn_next = struct.unpack_from(
                    endian + "III", data, pos + 4
                )
                vn_cnt = struct.unpack_from(endian + "H", data, pos + 2)[0]
                aux_pos = pos + vn_aux
                for _ in range(vn_cnt):
                    vna_name, vna_next = struct.unpack_from(
                        endian + "II", data, aux_pos + 8
                    )
                    verstr = read_str(dynstr_off, vna_name)
                    if verstr.startswith("GLIBC_"):
                        glibc_versions.append(verstr[len("GLIBC_") :])
                    if vna_next == 0:
                        break
                    aux_pos += vna_next
                if vn_next == 0:
                    break
                pos += vn_next
    except (struct.error, IndexError):
        glibc_versions = []
    return glibc_versions


def version_key(v):
    """Sort key for "x.y.z"-style version strings, numeric per component."""
    return tuple(int(p) for p in v.split(".") if p.isdigit())


def parse_elf(data):
    """Parse the subset of ELF structures this tool needs. Raises
    ElfParseError on anything that doesn't look like a well-formed ELF file
    - that failure mode is deliberate: a corrupted binary (like issue #107)
    should show up as a hard failure, not a silently empty report."""
    header = _read_elf_header(data)
    interp, min_kernel, has_interp_segment = _scan_program_headers(data, header)
    glibc_versions = _scan_glibc_versions(data, header)
    max_glibc = max(glibc_versions, key=version_key, default=None)
    e_machine = header["e_machine"]

    return {
        "e_machine": e_machine,
        "e_machine_name": EM_MACHINE_NAMES.get(e_machine, f"unknown(0x{e_machine:x})"),
        "class": "64-bit" if header["is64"] else "32-bit",
        "endian": "little" if header["ei_data"] == 1 else "big",
        "is_dynamic": has_interp_segment,
        "interp": interp,
        "min_kernel": min_kernel,
        "glibc_versions_referenced": sorted(set(glibc_versions), key=version_key),
        "max_glibc_required": max_glibc,
    }


def check_binary(path, arch):
    """Parse one binary and check it against ARCH_EXPECTATIONS[arch]."""
    result = {"path": path, "arch": arch, "ok": True, "errors": [], "warnings": []}

    try:
        with open(path, "rb") as f:
            data = f.read()
    except OSError as exc:
        result["ok"] = False
        result["errors"].append(f"cannot read file: {exc}")
        return result

    if len(data) == 0:
        result["ok"] = False
        result["errors"].append("file is empty")
        return result

    try:
        info = parse_elf(data)
    except ElfParseError as exc:
        result["ok"] = False
        result["errors"].append(f"not a valid ELF file: {exc}")
        return result

    result.update(info)

    expected = ARCH_EXPECTATIONS.get(arch)
    if expected is None:
        result["warnings"].append(
            f"unknown --arch '{arch}', skipping expectation checks "
            f"(known: {', '.join(sorted(ARCH_EXPECTATIONS))})"
        )
        return result

    if info["e_machine"] != expected["machine"]:
        result["ok"] = False
        want = EM_MACHINE_NAMES.get(expected["machine"], expected["machine"])
        result["errors"].append(
            f"wrong architecture: expected e_machine={want}, "
            f"got {info['e_machine_name']}"
        )

    is_static = not info["is_dynamic"]
    if is_static != expected["static"]:
        result["ok"] = False
        result["errors"].append(
            f"expected {'static' if expected['static'] else 'dynamic'} binary, "
            f"got {'static' if is_static else 'dynamic'} "
            f"(interp={info['interp']!r})"
        )

    if expected["float_abi"] and info["interp"]:
        is_hard = "armhf" in info["interp"]
        want_hard = expected["float_abi"] == "hard"
        if is_hard != want_hard:
            result["ok"] = False
            result["errors"].append(
                f"expected {expected['float_abi']}-float ABI, "
                f"interp is {info['interp']!r}"
            )

    return result


def main():
    """CLI entry point: validate_elf.py --arch <name> <path> [<path> ...]."""
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument(
        "--arch", required=True, help="Makefile ARCH= value this binary was built for"
    )
    ap.add_argument("paths", nargs="+", help="binary file(s) to validate")
    ap.add_argument("--json-out", help="write the full JSON report to this path")
    args = ap.parse_args()

    results = [check_binary(p, args.arch) for p in args.paths]

    for r in results:
        status = "OK" if r["ok"] else "FAIL"
        print(f"[{status}] {r['path']} (arch={r['arch']})")
        if r["ok"] and "e_machine_name" in r:
            print(
                f"       {r['e_machine_name']}, {r['class']}, "
                f"{'dynamic' if r['is_dynamic'] else 'static'}, "
                f"min_kernel={r['min_kernel']}, "
                f"max_glibc={r['max_glibc_required']}, "
                f"interp={r['interp']}"
            )
        for w in r["warnings"]:
            print(f"       warning: {w}")
        for e in r["errors"]:
            print(f"       error: {e}")

    if args.json_out:
        with open(args.json_out, "w", encoding="utf-8") as f:
            json.dump(results, f, indent=2)

    if not all(r["ok"] for r in results):
        sys.exit(1)


if __name__ == "__main__":
    main()
