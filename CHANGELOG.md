# Changelog

Changes to the **AirConnect-Synology packaging** itself — installer scripts, build
pipeline, and packaging logic. This is separate from AirConnect's own changelog
(bundled in each release as `CHANGELOG`, sourced from
[philippe44/AirConnect](https://github.com/philippe44/AirConnect/blob/master/CHANGELOG)).

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Fixed

- **Package Center could report AirConnect as "stopped" while it was actually running
  healthy.** Both `airconnect_status()` (the status check) and `stop_airconnect()`'s
  own success verification in `start-stop-status` used bare `ps` to look for the
  `airupnp`/`aircast` processes; since both daemonize (detach from any controlling
  terminal), bare `ps` could never see them, regardless of whether they were actually
  running or had actually stopped. Fixed to use `ps aux` throughout, matching what the
  PID-lookup used for killing already did correctly. Verified on real hardware (DS415+,
  DSM 7.1.1): before the fix, a fully healthy install (discovering and streaming to
  real devices) was reported as `stopped` (`status_code 3`) at every check; after the
  fix, the identical install correctly reports `running` (`status_code 0`). Likely the
  root cause of several long-standing "package shows stopped after install" reports.
  Applies to both the DSM 7 and legacy DSM 5/6 packages.
