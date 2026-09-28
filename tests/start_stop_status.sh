#!/bin/sh
# Check what start-stop-status reports and does in the states an
# installation can really be in - not only the healthy one.
#
# DSM calls "status" every few seconds and "stop" before every update and
# uninstall, whatever state the installation is in. So both must answer
# from what is actually running: with the config missing, Package Center
# must not show "stopped" while the processes run, and stopping must still
# work. Only "start" needs the settings.
#
# The processes are stand-ins: small scripts named airupnp/aircast in the
# package directory, so their command line carries the package path just
# like the real binaries'. (Copies of `sleep` would be simpler, but macOS
# kills a copied system binary on start.)
#
# Usage: tests/start_stop_status.sh [src/dsm7 | src/dsm]   (default: both)
# Exit status: 0 if every scenario behaves as expected.

set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
# An unusual duration, so leftover sleeps can be told apart from anyone else's.
FAKE_SECONDS=6007
FAIL=0
RUN=0
WORK=""

fail() {
    echo "  FAIL: $1"
    FAIL=1
}

pass() {
    echo "  ok: $1"
}

# expect <description> <command...>: one check, passing if the command does.
expect() {
    RUN=$((RUN + 1))
    desc=$1
    shift
    if "$@"; then
        pass "$desc"
    else
        fail "$desc"
    fi
}

setup() {
    WORK=$(mktemp -d)
    mkdir -p "$WORK/pkg/log" "$WORK/vol"
    export SYNOPKG_PKGDEST="$WORK/pkg"
    export SYNOPKG_PKGDEST_VOL="$WORK/vol"
    export SYNOPKG_PKGNAME="AirConnect"
    export SYNOPKG_TEMP_LOGFILE="$WORK/dsm-message.log"
    : >"$SYNOPKG_TEMP_LOGFILE"
    CONFIG="$SYNOPKG_PKGDEST/airconnect.conf"
}

teardown() {
    stop_fakes
    rm -rf "$WORK"
    WORK=""
}

config_present() {
    cat >"$CONFIG" <<'CONF'
SYNO_IP="192.0.2.10"
AIRUPNP_ENABLED=1
AIRCAST_ENABLED=1
AIRUPNP_PORT="49154"
AIRUPNP_LOGLEVEL="all=info"
AIRCAST_LOGLEVEL="all=info"
CONF
}

# fake <dir> <name>: a process whose command line is "sh <dir>/<name>".
fake() {
    printf '#!/bin/sh\nsleep %s\n' "$FAKE_SECONDS" >"$1/$2"
    sh "$1/$2" &
}

start_fake() {
    fake "$SYNOPKG_PKGDEST" "$1"
}

stop_fakes() {
    [ -n "$WORK" ] || return 0
    pkill -f "$WORK/" 2>/dev/null || true
    pkill -f "sleep $FAKE_SECONDS" 2>/dev/null || true
}

# shellcheck disable=SC2329 # used through expect
running() {
    # shellcheck disable=SC2009
    ps aux | grep -v grep | grep -q "$SYNOPKG_PKGDEST/$1"
}

# shellcheck disable=SC2329 # used through expect
not_running() {
    ! running "$1"
}

# sss <action>: run start-stop-status, print its exit code.
sss() {
    code=0
    sh "$TREE/scripts/start-stop-status" "$1" >/dev/null 2>&1 || code=$?
    echo "$code"
}

trap 'stop_fakes' EXIT INT TERM

check_tree() {
    TREE="$REPO_ROOT/$1"
    echo "== $1 =="

    # Healthy and running.
    setup
    config_present
    start_fake airupnp
    start_fake aircast
    expect "config present, both running: status is running" [ "$(sss status)" = "0" ]
    teardown

    # Healthy, one of the two has died: not "running", so it can be restarted.
    setup
    config_present
    start_fake aircast
    expect "config present, airupnp died: status is not running" [ "$(sss status)" = "3" ]
    teardown

    # The config disappeared while the package runs. Package Center must
    # still see it running, and Stop must still stop it.
    setup
    start_fake airupnp
    start_fake aircast
    expect "config missing, both running: status is running" [ "$(sss status)" = "0" ]
    expect "config missing, both running: stop succeeds" [ "$(sss stop)" = "0" ]
    expect "config missing, after stop: airupnp is gone" not_running airupnp
    expect "config missing, after stop: aircast is gone" not_running aircast
    teardown

    # The config is missing and nothing runs: broken, and starting must say
    # why instead of failing silently.
    setup
    expect "config missing, nothing running: status reports the package broken" [ "$(sss status)" = "150" ]
    expect "config missing, nothing running: stop succeeds" [ "$(sss stop)" = "0" ]
    expect "config missing: start refuses" [ "$(sss start)" = "150" ]
    expect "config missing: start tells DSM to reinstall" grep -q "reinstall" "$SYNOPKG_TEMP_LOGFILE"
    teardown

    # One of two binaries died, so status says stopped and Package Center
    # offers Run. Starting must not run the survivor a second time. The
    # config has no SYNO_IP, so start stops after the cleanup and before
    # launching anything - which is all this checks.
    setup
    config_present
    sed 's/^SYNO_IP=.*/SYNO_IP=""/' "$CONFIG" >"$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"
    start_fake aircast
    sss start >/dev/null
    expect "one binary died, start: the survivor is stopped first" not_running aircast
    teardown

    # Stop with the config present, the ordinary case.
    setup
    config_present
    start_fake airupnp
    start_fake aircast
    expect "config present: stop succeeds" [ "$(sss stop)" = "0" ]
    expect "config present, after stop: nothing left running" not_running airupnp
    teardown

    # Something else on the system called aircast is not ours: it must not
    # make the package look running.
    setup
    config_present
    mkdir -p "$WORK/elsewhere"
    fake "$WORK/elsewhere" aircast
    fake "$WORK/elsewhere" airupnp
    expect "only foreign airupnp/aircast running: status is not running" [ "$(sss status)" = "3" ]
    teardown
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
