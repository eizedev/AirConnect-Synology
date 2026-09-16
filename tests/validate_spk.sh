#!/bin/sh
# Validate the structure of a built AirConnect .spk package: required
# members present, INFO has all mandatory fields and no leftover
# unsubstituted placeholders (#VERSION# etc. - a silent Makefile sed
# failure would otherwise ship an INFO file DSM either rejects or shows
# garbled), payload binaries present and executable, lifecycle scripts
# present/executable/have a shebang, icons are valid PNGs.
#
# A .spk is an uncompressed tar (see src/dsm7/Makefile's final `tar -cf`
# step) containing package.tgz (gzipped payload) plus INFO, scripts/,
# conf/, WIZARD_UIFILES/, LICENSE, CHANGELOG, and both icon PNGs at the
# top level.
#
# Usage: validate_spk.sh <path-to.spk> [<path-to.spk> ...]
# Exit status: 0 if every package passes all hard checks.

set -eu

FAIL=0
WARN=0

fail() {
    echo "  FAIL: $1"
    FAIL=1
}

warn() {
    echo "  WARN: $1"
    WARN=1
}

# Read one KEY="value" or KEY=value assignment from an INFO file without
# executing it as shell (INFO is trusted - it's our own build output - but
# there is no reason to `source` a config file when a grep suffices).
info_field() {
    key="$1"
    file="$2"
    line=$(grep -E "^${key}=" "$file" | head -n1) || true
    value=$(printf '%s' "$line" | sed -E "s/^${key}=\"?([^\"]*)\"?\$/\1/")
    printf '%s' "$value"
}

check_one() {
    spk="$1"
    echo "== $spk =="

    if [ ! -f "$spk" ]; then
        fail "file does not exist"
        return
    fi

    workdir=$(mktemp -d)
    trap 'rm -rf "$workdir"' EXIT

    if ! tar -tf "$spk" >/dev/null 2>&1; then
        fail "not a valid tar archive"
        return
    fi
    tar -xf "$spk" -C "$workdir"

    # --- required top-level members -----------------------------------
    for member in INFO package.tgz LICENSE PACKAGE_ICON.PNG PACKAGE_ICON_256.PNG; do
        [ -f "$workdir/$member" ] || fail "missing required file: $member"
    done
    for dir in scripts conf WIZARD_UIFILES; do
        [ -d "$workdir/$dir" ] || fail "missing required directory: $dir"
    done
    # CHANGELOG is curl'ed from upstream at build time; its absence would
    # mean that curl step failed silently (Makefile does not check its
    # exit status against network errors).
    [ -f "$workdir/CHANGELOG" ] || warn "missing CHANGELOG (upstream curl step may have failed)"

    if [ ! -f "$workdir/INFO" ]; then
        echo "  (skipping INFO field checks - file is missing)"
    else
        info="$workdir/INFO"

        # Leftover template placeholders mean the Makefile's sed
        # substitution silently did not run/match.
        if grep -qE '#VERSION#|#INFO_ARCH#|#INFO_FIRMWARE#' "$info"; then
            fail "INFO still contains unsubstituted placeholder(s): $(grep -oE '#[A-Z_]+#' "$info" | tr '\n' ' ')"
        fi

        for field in package version description arch maintainer os_min_ver; do
            val=$(info_field "$field" "$info")
            if [ -z "$val" ]; then
                fail "INFO field '$field' is missing or empty"
            fi
        done

        arch_val=$(info_field arch "$info")
        if [ -n "$arch_val" ]; then
            echo "  arch: $arch_val"
        fi

        version_val=$(info_field version "$info")
        [ -n "$version_val" ] && echo "  version: $version_val"
    fi

    # --- payload (package.tgz) -----------------------------------------
    if [ -f "$workdir/package.tgz" ]; then
        pdir="$workdir/payload"
        mkdir -p "$pdir"
        if ! tar -xzf "$workdir/package.tgz" -C "$pdir" 2>/dev/null; then
            fail "package.tgz is not a valid gzipped tar"
        else
            for bin in airupnp aircast; do
                if [ ! -f "$pdir/$bin" ]; then
                    fail "package.tgz missing binary: $bin"
                elif [ ! -x "$pdir/$bin" ]; then
                    fail "$bin is not executable in package.tgz"
                fi
            done
            [ -d "$pdir/etc" ] || warn "package.tgz missing etc/ (airconnect.conf template, syslog config)"
            [ -d "$pdir/log" ] || warn "package.tgz missing log/ placeholder directory"
        fi
    fi

    # --- lifecycle scripts -----------------------------------------------
    if [ -d "$workdir/scripts" ]; then
        for script in preinst postinst preuninst postuninst preupgrade postupgrade start-stop-status; do
            sp="$workdir/scripts/$script"
            if [ ! -f "$sp" ]; then
                fail "missing scripts/$script"
                continue
            fi
            [ -x "$sp" ] || fail "scripts/$script is not executable"
            first_line=$(head -n1 "$sp")
            case "$first_line" in
                '#!'*) : ;;
                *) fail "scripts/$script has no shebang line (found: '$first_line')" ;;
            esac
        done
    fi

    # --- icons: must be valid PNGs; flag (not fail) unexpected dimensions,
    # since a deliberate icon redesign is legitimate, but an accidental
    # corruption/truncation during the build is not. Baselines below are
    # what ships today, not an asserted Synology spec (we don't have a
    # confirmed source for hard pixel-size requirements per DSM version).
    check_png() {
        png="$1"
        expect_dim="$2"
        [ -f "$png" ] || return 0
        magic=$(od -An -tx1 -N8 "$png" | tr -d ' \n')
        if [ "$magic" != "89504e470d0a1a0a" ]; then
            fail "$(basename "$png") is not a valid PNG (bad magic bytes)"
            return
        fi
        # IHDR width/height: big-endian uint32 at byte offsets 16 and 20
        w_hex=$(od -An -tx1 -j16 -N4 "$png" | tr -d ' \n')
        h_hex=$(od -An -tx1 -j20 -N4 "$png" | tr -d ' \n')
        width=$((0x$w_hex))
        height=$((0x$h_hex))
        echo "  $(basename "$png"): ${width}x${height}"
        if [ -n "$expect_dim" ] && [ "${width}x${height}" != "$expect_dim" ]; then
            warn "$(basename "$png") is ${width}x${height}, expected ${expect_dim} (dimensions changed - deliberate?)"
        fi
    }
    check_png "$workdir/PACKAGE_ICON.PNG" "64x64"
    check_png "$workdir/PACKAGE_ICON_256.PNG" "256x256"

    rm -rf "$workdir"
    trap - EXIT
}

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path-to.spk> [<path-to.spk> ...]" >&2
    exit 2
fi

for spk in "$@"; do
    check_one "$spk"
done

if [ "$FAIL" -eq 1 ]; then
    echo "RESULT: FAIL"
    exit 1
fi
echo "RESULT: OK$( [ "$WARN" -eq 1 ] && echo ' (with warnings)' )"
