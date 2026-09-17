# Changelog

Changes to the **AirConnect-Synology packaging** — installer scripts, build pipeline,
config handling. For changes to `airupnp`/`aircast` themselves, see the upstream
[AirConnect CHANGELOG](https://github.com/philippe44/AirConnect/blob/master/CHANGELOG)
(bundled in each release). Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Entries before 1.11.3 are
condensed from the [GitHub Releases](https://github.com/eizedev/AirConnect-Synology/releases)
history, which remains the canonical source for full release notes. Issue/discussion
links are included where a change traces back to one, so reports stay findable.

## [Unreleased]

## [1.11.3-20260917] - 2026-09-17

### Changed

- The `airconnect` shared folder is no longer used by default. Editing
  `airconnect.conf`/`config.xml`/`config-cast.xml` and viewing the log over SMB without
  SSH required enabling "allow symlinks" for SMB device-wide - a security tradeoff that
  shouldn't be forced on everyone just to install this package, most of whom never touch
  either file. A new install-wizard option, **"Enable shared-folder links", off by
  default**, lets you opt in if you want that convenience; nothing is linked into the
  shared folder unless checked. Note this only controls the _links_ - the empty
  `airconnect` folder itself is still created on every install regardless of the
  checkbox (Synology's `data-share` resource provisions it unconditionally, above the
  package's own scripts, with no supported way to make that conditional - see the
  README for why, and for the manual removal steps if you don't want it at all). The
  link option reappears on every upgrade, preselected with your current choice, so it
  can be changed later without reinstalling. Confirmed working end-to-end
  over real SMB (Finder/Windows Explorer), including editing `airconnect.conf` and
  saving it back; **not** supported via File Station (doesn't display symlinks at all)
  or AFP (no equivalent setting exists there). Addresses
  [discussion #132](https://github.com/eizedev/AirConnect-Synology/discussions/132).
- Replaced the syslog-ng-based log mirror (`etc/airconnect.conf`, a static config that
  could only ever write to a hardcoded `/volume1/...` path regardless of which volume
  the package was actually installed on, at world-writable `0666`) with a plain symlink
  into the shared folder, created only when the option above is enabled. The package's
  own `log/` directory is now always readable via SSH regardless of that setting (it was
  previously owner-only `0700` for no principled reason - nothing in the log is more
  sensitive than what's already in `airconnect.conf`, which was already world-readable).
- Added an uninstall-wizard option, **off by default**, to delete the _contents_ of the
  shared folder. The folder/registration itself persists either way - Synology's
  packaging system gives no unprivileged way to remove a shared folder it created (its
  own `data-share` resource documents this as deliberate: removing a folder
  automatically "might delete the user's personal data"), so this is the most that's
  achievable without an SSH step. Also, **on every uninstall regardless of this
  setting**, `airconnect.conf` and the log are copied into the shared folder first (real
  files, not symlinks) before the package directory where they normally live is removed
  - otherwise they'd be gone with no way back even for installs that never used shared-
    folder links, unlike the old syslog-ng mirror this replaced, which kept an independent
    copy of the log for exactly this reason.

### Fixed

- `get_pid()` matched bare `airupnp`/`aircast` against the whole process table with no
  path scoping, so `stop_airconnect()` could in principle kill an unrelated process that
  merely had one of those strings somewhere in its own command line. Now matches on the
  full install path instead.
- `stop_airconnect()` sent SIGTERM, waited 10s, and would then just report "still
  running" forever if the process ignored it - never escalating, leaving the package
  stuck unable to stop, uninstall, or upgrade against a hung process. Now sends SIGKILL
  if anything's still up after the wait.
- The port-in-use check (`netstat -tln | grep :"$PORT"`) was an unanchored substring
  match: port `4915` would false-positive against an unrelated listener on `49154` or
  `49150`, refusing to start over a port that wasn't actually in use.

## [1.11.3-20260916] - 2026-09-16

Verified end-to-end on real hardware: fresh GUI install on a Synology router
(RT2600ac/SRM), and an upgrade from a real, previously-installed 1.8.3 on a DS923+
(DSM), config preserved.

### Added

- `AIRUPNP_PORTRANGE` config option: a fixed port range for airupnp's per-device
  RTP/HTTP streams, so firewall rules have something fixed to allow instead of random
  OS-assigned ports. Passed through as airupnp's `-a` flag. Default `49155:128`.
  ([#142](https://github.com/eizedev/AirConnect-Synology/issues/142))
- Automated upstream-update flow ([#19](https://github.com/eizedev/AirConnect-Synology/issues/19)):
  a weekly check opens a PR when upstream AirConnect has a new release (checksum
  pre-verified, upstream release notes attached); merging that PR automatically tags
  and publishes the next AirConnect-Synology release. No auto-merge - review and
  merging the PR is still a human decision.

### Fixed

- Package Center could report AirConnect as "stopped" while it was actually running
  (`start-stop-status` used bare `ps`, which can't see daemonized processes on DSM).
  Now probes at runtime which `ps` invocation works, since DSM and SRM need opposite
  approaches (SRM's BusyBox `ps` errors on the `aux` flag DSM requires). Likely
  explains several long-standing "shows stopped after install" reports
  ([discussion #50](https://github.com/eizedev/AirConnect-Synology/discussions/50),
  [#85](https://github.com/eizedev/AirConnect-Synology/issues/85)), though not
  confirmed retroactively for those specific reports.
- Package installation could fail outright on Synology routers (SRM) and leave the
  device unable to reinstall: every lifecycle script and `install_uifile.sh` were
  tracked in Git as non-executable, which DSM tolerates but SRM does not. Fixed for
  all scripts in both the DSM 7 and legacy DSM 5/6 packages.
- The installer's IP auto-detection crashed silently on SRM (`grep -P`, unsupported by
  BusyBox `grep`), leaving the IP field blank. Switched to the portable `sed` approach
  already used by the legacy DSM 5/6 installer.
- `preupgrade`/`postupgrade` referenced `$AIRCONNECT_USER` without ever setting it,
  sending their log output to `log/.log` instead of `log/airconnect.log`.

### Known issues

- The installer's auto-detected default IP can be wrong on multi-homed devices
  (confirmed: a router with a VPN/mesh interface as its default route got that
  interface's IP pre-filled, not its LAN IP). The field is editable, so this doesn't
  block installation. Not fixed - needs a considered choice of which interface to
  prefer on an ambiguous setup, not a quick patch.

## Earlier history (condensed from GitHub Releases)

- **1.8.3** (2024-04-03) - GitHub Actions now build and publish releases
  automatically; `airconnect.log` auto-rotates at 50MB; new
  `AIRUPNP_CONTENTLENGTH_MODE` config option; default latency lowered to `50:500`
  (existing configs not touched - update manually); fixed a corrupted-binary release
  caused by a `release-downloader` bug
  ([#107](https://github.com/eizedev/AirConnect-Synology/issues/107),
  [#108](https://github.com/eizedev/AirConnect-Synology/pull/108), thanks @seiry).
  Playback-latency work tracked in
  [#79](https://github.com/eizedev/AirConnect-Synology/issues/79).
- **1.6.3 / 1.7.0** (2024-01) - first (preliminary) GitHub Actions build automation.
- **1.2.2** (2023-10-01) - no packaging changes; tracked upstream AirConnect only.
- **1.1.0-1.1.7** (2023-04 to 2023-08) - `armv5` build re-added; upstream aircast
  volume-control fix.
- **1.0.13** (2022-12-16) - AirConnect 1.0 support
  ([#57](https://github.com/eizedev/AirConnect-Synology/issues/57)); new
  architectures `epyc7002`, `r1000`, `broadwellnkv2` (DS923+ and newer); static
  builds added for `armv5`, `armv6`, `x86`, `x86_64`.
- **0.2.51.2** (2021-11 to 2022-02) - security fix for CVE-2017-12087 (upstream);
  default AirPlay-device filter extended: Samsung HW-N950
  ([#52](https://github.com/eizedev/AirConnect-Synology/issues/52)), Devialet Expert
  Pro 140 ([#46](https://github.com/eizedev/AirConnect-Synology/issues/46)),
  Fitzwilliam ([#47](https://github.com/eizedev/AirConnect-Synology/issues/47)) -
  filter is not touched on upgrade, only on fresh installs.
- **0.2.50.5 "dsm7" series** (2021-07 to 2021-08) - the DSM 7 rewrite: packages run
  under a dedicated `airconnect` user instead of root; integrated Package Center
  install wizard; `airconnect.conf` config file; dedicated `airconnect` shared folder
  for log/config access via File Station
  ([#22](https://github.com/eizedev/AirConnect-Synology/issues/22),
  [#16](https://github.com/eizedev/AirConnect-Synology/issues/16)). Breaking change -
  required uninstalling the old package first.
- **0.2.43.x - 0.2.44.x** (2021-01 to 2021-03) - `v1000`/`geminilake`/`purley`
  architecture support (DS1821+, DS1621+, and newer Celeron/Xeon models); local
  network interface detection fixes
  ([#11](https://github.com/eizedev/AirConnect-Synology/issues/11)); startup
  device-redetection removed pending a better fix
  ([#16](https://github.com/eizedev/AirConnect-Synology/issues/16)); log size cap
  lowered to 10MB; fixed a bug where Chromecast devices would disappear.
- **0.2.41.0** (2020-12-09) - default filter added for Sonos devices with native
  AirPlay support, to stop them appearing twice (the `FILTER_AIRPLAY2_DEVICES`
  mechanism still in use today;
  [#7](https://github.com/eizedev/AirConnect-Synology/issues/7), thanks
  @nathangoodman).
- **0.2.28.x** (2020-10-28) - `aarch64-static`/`arm-static` builds added.
- **0.2.26.0 → 0.2.26.1** (2020-05-26/28) - a same-week regression: low-privileged-user
  installs core-dumped on startup; fixed within two days.
- **0.2.25.0** (2020-05-04/11) - packages for all architectures published; upgrades no
  longer require uninstalling the previous version first.
- **0.2.24.7** (2020-04-17/20) - the original DSM package: `postinst`/`preuninst`/
  `postuninst` lifecycle scripts, dedicated package user, `config.xml`/
  `config-cast.xml` support, port-in-use check, Sonos latency defaults (`-l 1000:2000`).
