# Changelog

Changes to the **AirConnect-Synology packaging** itself — installer scripts, build
pipeline, and packaging logic. This is separate from AirConnect's own changelog
(bundled in each release as `CHANGELOG`, sourced from
[philippe44/AirConnect](https://github.com/philippe44/AirConnect/blob/master/CHANGELOG)).

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Fixed

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

### Known issues

- **SRM (Synology router) package installation is currently unreliable** and not yet
  root-caused: on a real RT2600ac, one install attempt "succeeded" per Package Center
  but never actually created `airconnect.conf` or wrote a log (so the package correctly
  refused to start, rather than silently misbehaving); a second attempt on the same,
  freshly-cleaned device failed the install outright. Until this is understood, router
  users should expect installation to potentially require more than one attempt, and
  are encouraged to report their exact SRM version and the install failure code if they
  hit this.
