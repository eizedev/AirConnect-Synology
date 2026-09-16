# Changelog

Changes to the **AirConnect-Synology packaging** itself — installer scripts, build
pipeline, and packaging logic. This is separate from AirConnect's own changelog
(bundled in each release as `CHANGELOG`, sourced from
[philippe44/AirConnect](https://github.com/philippe44/AirConnect/blob/master/CHANGELOG)).

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Known issues

- **On a real Synology router (RT2600ac/SRM), installing via the `synopkg` command
  line never populates the installer wizard's values at all** - `AIRUPNP_PORT` and
  `SYNO_IP` both come back completely empty in `airconnect.conf`, even after fixing
  the `grep -P` crash below (confirmed: the underlying IP-detection command works
  correctly when run directly on the same device, but its result never reaches
  `postinst`). Since this affects `AIRUPNP_PORT` too - a plain hardcoded default
  ("49154") that doesn't depend on any command at all - the most likely explanation is
  that the wizard step itself doesn't run for a command-line install on SRM, not a bug
  in either field's own default-value logic. Not root-caused at the `synopkg`/SRM
  level (closed-source). **Whether a real install through the actual Package Center
  GUI on SRM works correctly is unknown** - the GUI runs the wizard interactively,
  which the CLI-only testing used here cannot exercise at all. Needs a real GUI-based
  install test on an SRM device to resolve either way.
- **Separately, and only observable once the point above is resolved: the installer's
  auto-detected default IP may be wrong on multi-homed devices, including some router
  setups.** The detection picks the source address of the machine's default route,
  which is not necessarily the LAN-facing address. Directly confirmed by running the
  detection command (not the full installer, per the point above) on the same real SRM
  router: it correctly returned that device's VPN/mesh interface address, not its LAN
  IP. The wizard field is editable, so this wouldn't block installation on its own -
  but a robust fix needs a considered decision about which interface to prefer on an
  ambiguous multi-homed setup, not a quick patch, so it's flagged rather than guessed
  at.

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
