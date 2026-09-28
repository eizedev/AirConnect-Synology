#!/bin/sh
# Simulate what an update does to an existing installation's settings.
#
# The package is installed by tens of thousands of people, most of them on
# a release old enough that it knows nothing about today's settings. An
# update must work out what such an installation is actually doing, from
# the device rather than from a config line the old package never wrote -
# and where it cannot, it must keep things as they are or refuse, never
# guess. This runs preupgrade and postupgrade against prepared
# installations and checks the result, so that promise is tested rather
# than assumed.
#
# The wizard (WIZARD_UIFILES/upgrade_uifile.sh) is exercised too, since
# what it preselects is what postupgrade receives. Between preupgrade and
# postupgrade the package directory is emptied, as DSM does when it swaps in
# the new package - otherwise a config preupgrade failed to save would still
# be in place and look carried over.
#
# Usage: tests/upgrade_state.sh [src/dsm7 | src/dsm]   (default: both)
# Exit status: 0 if every scenario behaves as expected.

set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
FAIL=0
RUN=0

fail() {
    echo "  FAIL: $1"
    FAIL=1
}

pass() {
    echo "  ok: $1"
}

# A throwaway copy of an installed package, as DSM would have it:
# $WORK/pkg   is SYNOPKG_PKGDEST (the installed files, incl. the config)
# $WORK/vol   is SYNOPKG_PKGDEST_VOL (holds the "airconnect" shared folder)
# $WORK/tmp   is SYNOPKG_TEMP_UPGRADE_FOLDER (preupgrade's backup)
setup() {
    WORK=$(mktemp -d)
    mkdir -p "$WORK/pkg/log" "$WORK/vol" "$WORK/tmp"
    export SYNOPKG_PKGDEST="$WORK/pkg"
    export SYNOPKG_PKGDEST_VOL="$WORK/vol"
    export SYNOPKG_TEMP_UPGRADE_FOLDER="$WORK/tmp"
    export SYNOPKG_PKGNAME="AirConnect"
    export SYNOPKG_TEMP_LOGFILE="$WORK/dsm-message.log"
    : >"$SYNOPKG_TEMP_LOGFILE"
    unset pkgwizard_create_shared_folder || true
}

teardown() {
    chmod -R u+w "$WORK" 2>/dev/null || true
    rm -rf "$WORK"
}

# A config as an old release left it: no shared-folder setting at all.
config_without_setting() {
    cat >"$SYNOPKG_PKGDEST/airconnect.conf" <<'CONF'
AIRCAST_ENABLED=1
AIRUPNP_ENABLED=1
SYNO_IP="192.168.1.2"
CONF
}

config_with_setting() {
    config_without_setting
    echo "AIRCONNECT_SHARED_FOLDER_LINKS_ENABLED=$1" >>"$SYNOPKG_PKGDEST/airconnect.conf"
}

# The shared folder as a release that always created it leaves it behind.
shared_folder_in_use() {
    mkdir -p "$SYNOPKG_PKGDEST_VOL/airconnect/log"
    ln -sf "$SYNOPKG_PKGDEST/airconnect.conf" "$SYNOPKG_PKGDEST_VOL/airconnect/airconnect.conf"
    touch "$SYNOPKG_PKGDEST_VOL/airconnect/log/airconnect.log"
}

setting_now() {
    sed -n 's/^AIRCONNECT_SHARED_FOLDER_LINKS_ENABLED=\(.*\)/\1/p' \
        "$SYNOPKG_PKGDEST/airconnect.conf" | tail -n 1
}

# What the wizard would preselect: "true", "false", or "none" when it
# leaves the checkbox out because it cannot tell.
wizard_answer() {
    answer=$(sh "$TREE/WIZARD_UIFILES/upgrade_uifile.sh" 2>/dev/null |
        sed -n 's/.*"defaultValue": \([a-z]*\).*/\1/p' | tail -n 1)
    echo "${answer:-none}"
}

# preupgrade, DSM swapping in the new package's files, postupgrade.
replace_package() {
    rm -rf "$SYNOPKG_PKGDEST"
    mkdir -p "$SYNOPKG_PKGDEST/log"
}

run_upgrade() {
    sh "$TREE/scripts/preupgrade" || return $?
    replace_package
    sh "$TREE/scripts/postupgrade" || return $?
}

expect_setting() {
    RUN=$((RUN + 1))
    actual=$(setting_now)
    if [ "$actual" = "$1" ]; then
        pass "$2 (setting is $actual)"
    else
        fail "$2 - expected setting $1, got '${actual:-<none>}'"
    fi
}

expect_wizard() {
    RUN=$((RUN + 1))
    actual=$(wizard_answer)
    if [ "$actual" = "$1" ]; then
        pass "$2 (wizard preselects $actual)"
    else
        fail "$2 - expected wizard $1, got '$actual'"
    fi
}

check_tree() {
    TREE="$REPO_ROOT/$1"
    echo "== $1 =="

    # The case that broke real installations: a config old enough not to
    # have the setting, on an installation that is using the shared
    # folder. Neither the wizard nor postupgrade may read that as "off".
    setup
    config_without_setting
    shared_folder_in_use
    expect_wizard "true" "config predates the setting, shared folder in use"
    run_upgrade
    expect_setting "1" "config predates the setting, shared folder in use"
    RUN=$((RUN + 1))
    if [ -L "$SYNOPKG_PKGDEST_VOL/airconnect/airconnect.conf" ]; then
        pass "existing links are left alone"
    else
        fail "existing links were removed although the folder is in use"
    fi
    teardown

    # Same, without the shared folder: nothing to preserve, and nothing
    # to guess either - the wizard offers no checkbox.
    setup
    config_without_setting
    expect_wizard "none" "config predates the setting, shared folder unused"
    run_upgrade
    expect_setting "0" "config predates the setting, shared folder unused"
    teardown

    # An explicit setting is authoritative, in both directions.
    setup
    config_with_setting 1
    shared_folder_in_use
    expect_wizard "true" "setting is on"
    run_upgrade
    expect_setting "1" "setting is on, no answer from the wizard"
    teardown

    setup
    config_with_setting 0
    expect_wizard "false" "setting is off"
    run_upgrade
    expect_setting "0" "setting is off, no answer from the wizard"
    teardown

    # An answer from the wizard is the user's decision and wins.
    setup
    config_with_setting 1
    shared_folder_in_use
    export pkgwizard_create_shared_folder="false"
    run_upgrade
    expect_setting "0" "user turns it off in the wizard"
    RUN=$((RUN + 1))
    if [ -L "$SYNOPKG_PKGDEST_VOL/airconnect/airconnect.conf" ]; then
        fail "links still there after the user turned it off"
    else
        pass "links removed after the user turned it off"
    fi
    unset pkgwizard_create_shared_folder
    teardown

    setup
    config_with_setting 0
    export pkgwizard_create_shared_folder="true"
    run_upgrade
    expect_setting "1" "user turns it on in the wizard"
    unset pkgwizard_create_shared_folder
    teardown

    # No config at all: the settings cannot be carried over, so the
    # update must stop rather than continue with invented ones.
    setup
    RUN=$((RUN + 1))
    if sh "$TREE/scripts/preupgrade" 2>/dev/null; then
        fail "update continued although there is no config to carry over"
    else
        if grep -q "uninstall" "$SYNOPKG_TEMP_LOGFILE"; then
            pass "update refused, and DSM is told to uninstall and reinstall"
        else
            fail "update refused, but the message doesn't say what to do"
        fi
    fi
    teardown

    # The config is there but cannot be saved, or saved but not put back.
    # Both must stop the update with a message rather than end in a package
    # without its settings. File permissions do not stop root, so these are
    # skipped when running as root.
    if [ "$(id -u)" -ne 0 ]; then
        setup
        config_with_setting 1
        chmod 500 "$SYNOPKG_TEMP_UPGRADE_FOLDER"
        RUN=$((RUN + 1))
        if sh "$TREE/scripts/preupgrade" 2>/dev/null; then
            fail "update continued although the config could not be saved"
        elif grep -q "uninstall\|could not be saved" "$SYNOPKG_TEMP_LOGFILE"; then
            pass "config cannot be saved: update refused, with a message for DSM"
        else
            fail "config cannot be saved: update refused, but DSM gets no message"
        fi
        teardown

        setup
        config_with_setting 1
        sh "$TREE/scripts/preupgrade"
        replace_package
        chmod 555 "$SYNOPKG_PKGDEST"
        RUN=$((RUN + 1))
        if sh "$TREE/scripts/postupgrade" 2>/dev/null; then
            fail "update reported success although the config could not be restored"
        elif grep -q "uninstall" "$SYNOPKG_TEMP_LOGFILE"; then
            pass "config cannot be restored: update fails, and DSM is told what to do"
        else
            fail "config cannot be restored: update fails, but the message doesn't say what to do"
        fi
        teardown
    else
        echo "  skip: config cannot be saved or restored (running as root)"
    fi
}

if [ $# -gt 0 ]; then
    for tree in "$@"; do check_tree "$tree"; done
else
    check_tree src/dsm7
    check_tree src/dsm
fi

echo
if [ "$FAIL" -eq 0 ]; then
    echo "All $RUN checks passed."
else
    echo "Some of the $RUN checks failed."
fi
exit "$FAIL"
