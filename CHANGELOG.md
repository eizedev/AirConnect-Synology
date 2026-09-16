# Changelog

Changes to the **AirConnect-Synology packaging** — installer scripts, build pipeline,
config handling. For changes to `airupnp`/`aircast` themselves, see the upstream
[AirConnect CHANGELOG](https://github.com/philippe44/AirConnect/blob/master/CHANGELOG)
(bundled in each release). Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Entries before 1.11.3 are
condensed from the [GitHub Releases](https://github.com/eizedev/AirConnect-Synology/releases)
history, which remains the canonical source for full release notes.

## [Unreleased]

Verified end-to-end on real hardware: fresh GUI install on a Synology router
(RT2600ac/SRM), and an upgrade from a real, previously-installed 1.8.3 on a DS923+
(DSM), config preserved.

### Fixed
- Package Center could report AirConnect as "stopped" while it was actually running
  (`start-stop-status` used bare `ps`, which can't see daemonized processes on DSM).
  Now probes at runtime which `ps` invocation works, since DSM and SRM need opposite
  approaches (SRM's BusyBox `ps` errors on the `aux` flag DSM requires).
- Package installation could fail outright on Synology routers (SRM) and leave the
  device unable to reinstall: every lifecycle script and `install_uifile.sh` were
  tracked in git as non-executable, which DSM tolerates but SRM does not. Fixed for
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
  caused by a `release-downloader` bug (thanks @seiry).
- **1.6.3 / 1.7.0** (2024-01) - first (preliminary) GitHub Actions build automation.
- **1.2.2** (2023-10-01) - no packaging changes; tracked upstream AirConnect only.
- **1.1.0-1.1.7** (2023-04 to 2023-08) - `armv5` build re-added; upstream aircast
  volume-control fix.
- **1.0.13** (2022-12-16) - AirConnect 1.0 support; new architectures `epyc7002`,
  `r1000`, `broadwellnkv2` (DS923+ and newer); static builds added for `armv5`,
  `armv6`, `x86`, `x86_64`.
- **0.2.51.2** (2021-11 to 2022-02) - security fix for CVE-2017-12087 (upstream);
  default AirPlay-device filter extended (Samsung HW-N950, Devialet Expert Pro 140,
  Fitzwilliam) - filter is not touched on upgrade, only on fresh installs.
- **0.2.50.5 "dsm7" series** (2021-07 to 2021-08) - the DSM 7 rewrite: packages run
  under a dedicated `airconnect` user instead of root; integrated Package Center
  install wizard; `airconnect.conf` config file; dedicated `airconnect` shared folder
  for log/config access via File Station. Breaking change - required uninstalling the
  old package first.
- **0.2.43.x - 0.2.44.x** (2021-01 to 2021-03) - `v1000`/`geminilake`/`purley`
  architecture support (DS1821+, DS1621+, and newer Celeron/Xeon models); local
  network interface detection fixes; log size cap lowered to 10MB; fixed a bug where
  Chromecast devices would disappear.
- **0.2.41.0** (2020-12-09) - default filter added for Sonos devices with native
  AirPlay support, to stop them appearing twice (the `FILTER_AIRPLAY2_DEVICES`
  mechanism still in use today).
- **0.2.28.x** (2020-10-28) - `aarch64-static`/`arm-static` builds added.
- **0.2.26.0 → 0.2.26.1** (2020-05-26/28) - a same-week regression: low-privileged-user
  installs core-dumped on startup; fixed within two days.
- **0.2.25.0** (2020-05-04/11) - packages for all architectures published; upgrades no
  longer require uninstalling the previous version first.
- **0.2.24.7** (2020-04-17/20) - the original DSM package: `postinst`/`preuninst`/
  `postuninst` lifecycle scripts, dedicated package user, `config.xml`/
  `config-cast.xml` support, port-in-use check, Sonos latency defaults (`-l 1000:2000`).
