# Architecture reference

Full package-naming and Synology-platform-code matrix. If you just want the short
version, see [Which package do I need?](../README.md#which-package-do-i-need) in the
main README - this page is for edge cases and reference lookups.

## Finding your platform code

Package Center filters visible packages by your device's platform code automatically -
you normally don't need to look this up yourself, it's only useful if a package doesn't
show up as installable and you want to understand why. Check the `Package Arch` column
on Synology's own
[What kind of CPU does my Synology NAS have?](https://www.synology.com/en-us/knowledgebase/DSM/tutorial/Compatibility_Peripherals/What_kind_of_CPU_does_my_NAS_have)
page.

## Package naming

| DSM firmware                                        | Package prefix                         | Example                                      |
| --------------------------------------------------- | -------------------------------------- | -------------------------------------------- |
| DSM 7.0-40000 and newer                             | `AirConnect-dsm7-`                     | `AirConnect-dsm7-x86_64-1.11.3-20260917.spk` |
| DSM 6.0-7321 and newer (x86_64 only)                | `AirConnect-` (legacy line, see below) | `AirConnect-x86_64-0.2.50.5-20260917.spk`    |
| DSM 5.0-4458 and newer (all other legacy platforms) | `AirConnect-` (legacy line, see below) | `AirConnect-arm-0.2.50.5-20260917.spk`       |

If the `x86` (32-bit) package doesn't work on your device, use `x86_64` (64-bit) instead.

## Architecture groups (DSM 7)

Ground truth, read directly from `src/dsm7/Makefile`'s `INFO_ARCH` per target - this is
exactly what each package declares as compatible in Package Center, not a hand-maintained
copy that can drift.

| Architecture group | Synology platform codes                                                                                                                                                                                                                                                                 | Package                              |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| ARMv5              | `88f6282`, `88f6281`, `88f628x`                                                                                                                                                                                                                                                         | `AirConnect-dsm7-armv5-${VERSION}`   |
| ARMv7              | `ipq806x`, `armada370`, `armadaxp`, `armada375`, `armada38x`, `alpine`, `alpine4k`, `monaco`, `comcerto2k`, `hi3535`, `dakota`, `northstarplus`, `hawkeye`                                                                                                                              | `AirConnect-dsm7-arm-${VERSION}`     |
| ARMv8 / AArch64    | `rtd1296`, `rtd1619b`, `armada37xx`, `cypress`                                                                                                                                                                                                                                          | `AirConnect-dsm7-aarch64-${VERSION}` |
| PowerPC            | `qoriq`, `ppc853x`                                                                                                                                                                                                                                                                      | `AirConnect-dsm7-powerpc-${VERSION}` |
| Intel/AMD 32-bit   | `x86`, `cedarview`, `bromolow`, `evansport`, `braswell`, `broadwell`, `dockerx64`, `kvmx64`, `denverton`, `grantley`, `broadwellnk`, `broadwellntbap`                                                                                                                                   | `AirConnect-dsm7-x86-${VERSION}`     |
| Intel/AMD 64-bit   | `x86_64`, `x64`, `cedarview`, `bromolow`, `avoton`, `braswell`, `broadwell`, `apollolake`, `dockerx64`, `epyc7002`, `r1000`, `r1000nk`, `kvmx64`, `denverton`, `grantley`, `broadwellnk`, `broadwellnkv2`, `broadwellntbap`, `v1000`, `v1000nk`, `geminilake`, `geminilakenk`, `purley` | `AirConnect-dsm7-x86_64-${VERSION}`  |

Every group above also has a `-static` variant with the identical platform list - see
[Static packages](#static-packages) for when to use it. `hawkeye`/`cypress` are Synology
router (SRM) platforms; the rest are NAS.

Cross-checked 2026-09-17 against SynoCommunity's actively-maintained
[`spksrc` architecture reference](https://raw.githubusercontent.com/SynoCommunity/spksrc/master/mk/spksrc.common/archs.mk),
which surfaced real drift from three years of no re-verification: several current-
generation models (`geminilakenk`, `v1000nk`, `r1000nk`) and router platforms
(`hawkeye`, `cypress`) were missing entirely, and an `armv6` package (removed, see
below) turned out to correspond to no real Synology hardware. See
[issue #222](https://github.com/eizedev/AirConnect-Synology/issues/222) for the full
before/after. Worth periodically re-checking against that same source as Synology
ships new models.

> **A separate `armv6` package existed up to and including release
> `1.11.3-20260917` and has since been removed.** It wasn't a packaging mistake -
> upstream AirConnect genuinely ships a distinct `armv6` binary, added in AirConnect
> 1.0.9 (2022) - but neither Synology's own documentation nor SynoCommunity's
> platform reference lists a single Synology device as ARMv6; Synology's Kirkwood
> devices are ARMv5. The `armv6` package declared the same platform codes as `armv5`
> purely for lack of a better option, offering an ARMv6-compiled binary to ARMv5TE
> hardware with no verified guarantee it would even run correctly there. If you were
> relying on the `armv6` package specifically (not just installed on a Kirkwood
> device via `armv5`), please
> [open an issue](https://github.com/eizedev/AirConnect-Synology/issues).

## Synology Router (SRM)

Most routers running Synology SRM use the **ARMv7** package
(`AirConnect-dsm7-arm-${VERSION}`, covers `northstarplus`/`ipq806x`/`dakota`/`hawkeye`).
If that doesn't work, try `arm-static`. A newer `cypress` platform is ARMv8 instead - use
the **aarch64** package for that one.

The packages are named `dsm7-*`, but the same package works on SRM as well as DSM 7 -
confirmed on a real router (RT2600ac, SRM 1.3.2-9366 Update 2), install through to a
running `airupnp`/`aircast`. Not independently re-confirmed on a second router model, so
treat this as "works on the tested unit," not a blanket guarantee across every SRM device
and patch level.

> **Check the pre-filled IP during install if your router has a VPN, mesh, or other
> non-LAN default route.** The installer wizard's "IP of your Synology device" field is
> auto-detected from your router's default route, which on such setups may not be your
> LAN address (e.g. a Tailscale/VPN interface's IP instead). If AirConnect isn't
> reachable after install, check the IP in `airconnect.conf` and correct it to your
> router's actual LAN IP if needed - the field is editable during install, or you can
> edit `airconnect.conf` afterward and restart the package.

## Static packages

Some older devices are missing shared libraries that `airupnp`/`aircast` need. Static
packages bundle those dependencies directly into the binary instead of relying on what's
already on the device - that's also why they're bigger.

Use the normal (non-static) package first. Only fall back to the static variant if the
normal one fails to start.

## Older DSM 5/6 devices

DSM 5/6 support lives in a separate, **frozen** package line (`src/dsm`, no `dsm7-`
prefix) - it stopped receiving new AirConnect versions once DSM 7 became the primary
target, and is pinned to AirConnect `0.2.50.5`. It still gets packaging-level fixes
(lifecycle script bugs, permissions), just not upstream feature/version bumps. Use the
[0.2.50.5-20210706](https://github.com/eizedev/AirConnect-Synology/releases/tag/0.2.50.5-20210706)
release, or a newer date-suffixed rebuild if one exists on the
[releases page](https://github.com/eizedev/AirConnect-Synology/releases).

> On DSM 5 and some DSM 6 devices, this isn't an official Synology package, so you may
> need to **allow packages from any publisher**: `Settings` → set `Trust Level` to
> "**Any publisher**". Change it back to "Synology Inc." afterward for security.

If your device is old enough that even this frozen line won't run (see
[Troubleshooting](TROUBLESHOOTING.md) for the "kernel too old" symptom), there currently
isn't a newer fallback - open an [issue](https://github.com/eizedev/AirConnect-Synology/issues)
with your device model and DSM version.
