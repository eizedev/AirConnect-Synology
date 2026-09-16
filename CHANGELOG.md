# Changelog

Changes to the **AirConnect-Synology packaging** itself — installer scripts, build
pipeline, and packaging logic. This is separate from AirConnect's own changelog
(bundled in each release as `CHANGELOG`, sourced from
[philippe44/AirConnect](https://github.com/philippe44/AirConnect/blob/master/CHANGELOG)).

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

All three fixes below were verified together end-to-end via a real Package Center
install on a Synology router (RT2600ac/SRM): install, wizard, start, and a running
`airupnp`/`aircast` all worked correctly through the actual GUI install path a real
user takes, after fixing the IP field's misleading VPN-interface default by hand (see
"Known issues" below).

### Known issues

- **The installer's auto-detected default IP can be wrong on multi-homed devices,
  including some router setups - confirmed, not just suspected.** The detection picks
  the source address of the machine's default route, which is not necessarily the
  LAN-facing address. Directly confirmed via a real Package Center install on an SRM
  router configured with a VPN/mesh interface as its default route: the wizard
  correctly rendered and pre-filled the "IP of your Synology device" field, but with
  that VPN interface's address rather than the device's LAN IP - the field had to be
  corrected by hand before completing the install. The field is editable, so this
  doesn't block installation, but the pre-filled default can be actively misleading on
  such setups. Not fixed - flagged as a known limitation of the detection heuristic
  rather than silently worked around, since a robust fix needs a considered decision
  about which interface to prefer on an ambiguous multi-homed setup, not a quick
  patch.

### Fixed

- **The installer's IP auto-detection could crash silently on Synology routers (SRM),
  leaving the "IP of your Synology device" field blank instead of pre-filled.** It
  used `grep -P` (PCRE) to parse `ip route` output; BusyBox's `grep` on SRM (and
  presumably on any Synology model that ships BusyBox instead of GNU grep) doesn't
  support `-P` at all and errors with "invalid option -- 'P'" - silently, since the
  script has no `set -e`, so the failure produced an empty IP instead of a visible
  error. Fixed by switching to the same `sed`-based approach the legacy DSM 5/6
  package's installer already used (which doesn't need PCRE) - confirmed by direct
  testing that this produces the identical, correct result on real DSM hardware
  (DS415+) and now also works without erroring on SRM (RT2600ac), where it previously
  crashed outright.

- **Package Center could report AirConnect as "stopped" while it was actually running
  healthy (DSM).** Both `airconnect_status()` (the status check) and
  `stop_airconnect()`'s own success verification in `start-stop-status` used bare `ps`
  to look for the `airupnp`/`aircast` processes; since both daemonize (detach from any
  controlling terminal), DSM's `ps` could never see them without the `aux` flag,
  regardless of whether they were actually running or had actually stopped. Verified on
  real hardware (DS415+, DSM 7.1.1): before the fix, a fully healthy install
  (discovering and streaming to real devices) was reported as `stopped`
  (`status_code 3`) at every check; after the fix, the identical install correctly
  reports `running` (`status_code 0`). Likely the root cause of several long-standing
  "package shows stopped after install" reports.
  - The fix now **probes which `ps` invocation actually works at runtime** instead of
    hard-coding `ps aux`: Synology routers (SRM) ship a BusyBox `ps` that does the
    opposite of DSM - it lists every process by default and **errors out** on `aux`.
    A first version of this fix that just switched everything to `ps aux` would have
    broken status/stop on routers while fixing DSM. Also fixes a separate, pre-existing
    bug in the PID lookup used by the stop path, which had always hard-coded `ps aux`
    even before this change - so `stop` was likely never able to find the right
    processes to kill on SRM/routers either.
  - Applies to both the DSM 7 and legacy DSM 5/6 packages.

- **Package installation could fail outright on Synology routers (SRM), and leave the
  device unable to reinstall afterward.** All lifecycle scripts (`preinst`, `postinst`,
  etc.) and `WIZARD_UIFILES/install_uifile.sh` were tracked in git as non-executable
  (mode `644`) instead of `755` - harmless on DSM, which invokes them via an
  interpreter, but fatal on SRM. Root-caused on a real RT2600ac via
  `/var/log/messages`:
  ```
  process.cpp:219 Failed to run .../WIZARD_UIFILES/install_uifile.sh, ret=[-1], Permission denied
  pkgtool.cpp:2430 AirConnect can't run
  pkgstartstop.cpp:216 Package target path broken, AirConnect
  ```
  That failure left the package registration broken, which then made a subsequent
  clean install attempt on the same device fail too. Fixed by setting the executable
  bit on every script in both the DSM 7 and legacy DSM 5/6 packages.
