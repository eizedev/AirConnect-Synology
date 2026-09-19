#!/bin/sh
# Print the value for INFO's `changelog` field - the "What's New" text
# Package Center shows next to an available update. Package sources that
# read INFO from the .spk (e.g. 007revad's) pass it through to the feed.
#
# Built from two sources so it covers both halves of what a release
# changes:
#   1. the packaging repo's CHANGELOG.md: the first sentence of every bullet
#      in the newest released section (the first `## [...]` heading that
#      isn't [Unreleased]), prefixed with its subsection so a fix doesn't
#      read like a new bug. Only the Keep a Changelog categories plus
#      "Known issues" are used - anything else (Internal, notes for
#      maintainers, ...) means nothing to someone updating in Package
#      Center, and an allowlist keeps new kinds of subsection out by default.
#   2. upstream's CHANGELOG: the entries for the bundled version. Format is
#      a version on its own line, then " - entry" lines.
# Links to both full changelogs are always appended. Anything that can't be
# found is left out rather than failing the build - the links alone are
# still a useful answer.
#
# Deliberately project-agnostic: the same file is used by AirConnect-Synology
# and SpotConnect-Synology, everything project-specific is an argument. Keep
# the copies identical.
#
# Usage: info_changelog.sh <package name> <CHANGELOG.md> <CHANGELOG.md URL> \
#            <upstream name> <upstream CHANGELOG> <upstream CHANGELOG URL> \
#            <upstream version>

set -eu

if [ $# -ne 7 ]; then
    echo "usage: $0 <package name> <CHANGELOG.md> <CHANGELOG.md URL> <upstream name> <upstream CHANGELOG> <upstream CHANGELOG URL> <upstream version>" >&2
    exit 2
fi

PKG_NAME="$1"
PKG_CHANGELOG="$2"
PKG_URL="$3"
UPSTREAM_NAME="$4"
UPSTREAM_CHANGELOG="$5"
UPSTREAM_URL="$6"
UPSTREAM_VERSION="$7"

# One bullet per output line: continuation lines (indented) are joined onto
# their bullet, a blank line ends it, so a bullet's follow-up paragraphs are
# ignored - only the first sentence is kept below anyway.
pkg_items() {
    [ -f "$PKG_CHANGELOG" ] || return 0
    awk '
        /^## \[/ {
            if (done) exit
            if ($0 ~ /^## \[Unreleased\]/) { insec = 0; next }
            insec = 1; done = 1; skip = 0; kind = ""; next
        }
        !insec { next }
        /^### / {
            flush()
            kind = substr($0, 5); sub(/[ \t]+$/, "", kind)
            skip = (kind !~ /^(Added|Changed|Deprecated|Removed|Fixed|Security|Known issues)$/)
            next
        }
        skip { next }
        /^- / { flush(); item = substr($0, 3); open = 1; next }
        /^[ \t]*$/ { flush(); next }
        /^  / { if (open) item = item " " substr($0, 3); next }
        { flush() }
        function flush() {
            if (item != "") print (kind != "" ? kind ": " : "") item
            item = ""; open = 0
        }
        END { flush() }
    ' "$PKG_CHANGELOG" |
        sed -E \
            -e 's/\[([^]]*)\]\([^)]*\)/\1/g' \
            -e 's/\*\*//g' \
            -e 's/`//g' \
            -e 's/(^|[ (])_([^_]+)_/\1\2/g' \
            -e 's/^(([^.]|\.[^ ])*\.)( .*)?$/\1/'
}

upstream_items() {
    [ -f "$UPSTREAM_CHANGELOG" ] || return 0
    awk -v ver="$UPSTREAM_VERSION" '
        { sub(/\r$/, "") }
        /^[0-9]/ { insec = ($1 == ver); next }
        insec && /^[ \t]*- / { sub(/^[ \t]*- /, ""); print }
    ' "$UPSTREAM_CHANGELOG"
}

out=""
add() { out="${out}$1<br/>"; }

items=$(pkg_items)
if [ -n "$items" ]; then
    add "${PKG_NAME} packaging:"
    n=0
    while IFS= read -r line; do
        n=$((n + 1))
        add "${n}. ${line}"
    done <<EOF
$items
EOF
    add ""
fi

items=$(upstream_items)
if [ -n "$items" ]; then
    add "Bundled ${UPSTREAM_NAME} ${UPSTREAM_VERSION}:"
    while IFS= read -r line; do
        add "- ${line}"
    done <<EOF
$items
EOF
    add ""
fi

add "Full packaging changelog: ${PKG_URL}"
out="${out}Full ${UPSTREAM_NAME} changelog: ${UPSTREAM_URL}"

# INFO is a key="value" file: the value must stay on one line and must not
# contain characters that would end or reinterpret the quoted string.
printf '%s\n' "$out" | tr -d '\n\r\\$`' | tr '"' "'"
