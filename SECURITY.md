# Security Policy

## Scope

This repository packages [AirConnect](https://github.com/philippe44/AirConnect) for
Synology NAS/routers - installer scripts, Package Center wizard files, the build
pipeline, and config handling. That's what's in scope here.

`airupnp`/`aircast` themselves (the actual AirPlay/UPnP/Chromecast bridging logic) are
upstream, maintained by [philippe44](https://github.com/philippe44) - a vulnerability in
the underlying binaries' own behavior belongs at
[philippe44/AirConnect](https://github.com/philippe44/AirConnect/security), not here.

## Reporting a vulnerability

Please report security issues in this repository's packaging privately via GitHub's
[Report a vulnerability](https://github.com/eizedev/AirConnect-Synology/security/advisories/new)
feature (`Security` tab → `Advisories` → `Report a vulnerability`), not a public issue -
this opens a private discussion until a fix is ready.

Please include:

- Which package/architecture and version
- Steps to reproduce, or the specific script/config involved
- What you expected vs. what actually happens

## Supported versions

Only the [latest release](https://github.com/eizedev/AirConnect-Synology/releases/latest)
is actively supported for the current DSM 7 package line. The legacy DSM 5/6 line
(`src/dsm`, see [doc/ARCHITECTURES.md](doc/ARCHITECTURES.md#older-dsm-56-devices)) is
frozen - it still receives packaging-level security fixes, just not upstream
feature/version updates.

## What to expect

This is a community-maintained hobby project, not a funded product with an SLA - reports
are read and taken seriously, but response time isn't guaranteed. Genuine packaging
vulnerabilities (an installer script doing something it shouldn't, insecure permissions
on files the package creates, etc.) will be fixed and released as soon as practical.
