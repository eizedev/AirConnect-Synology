# Troubleshooting

## Package won't install, update, or start

If you get an error installing, updating, or starting AirConnect-Synology, uninstall the
existing version first (`Package Center` → `AirConnect` → `Uninstall`), then install the
new one fresh.

Uninstalling removes the old scripts, references, and configuration. Unless you checked
**"Delete the contents..."** during uninstall, `airconnect.conf` and the log are backed
up into the `airconnect` shared folder first - see
[Editing files from your PC](../README.md#editing-files-from-your-pc). This alone
sometimes clears up the problem.

If a normal uninstall doesn't work either, clean up manually via SSH as root:

```bash
# Remove the package directory
rm -rf /var/packages/AirConnect

# Deregister the shared folder (only works on the legacy DSM 5/6 line - DSM 7
# doesn't allow packages, or their scripts, to do this; see the README's shared-folder
# section for why)
synoshare --del TRUE airconnect

# Remove the package's dedicated users/group
synouser --del airconnect
synouser --del airconnect__PKG_
synogroup --del airconnect
```

Then install the new package again - see
[Which package do I need?](../README.md#which-package-do-i-need).

## "FATAL: kernel too old" / crashes immediately on old hardware

This is a real, developer-confirmed failure mode on some older Synology devices,
documented in detail in
[issue #63](https://github.com/eizedev/AirConnect-Synology/issues/63) (with input from
AirConnect's own author) and [#104](https://github.com/eizedev/AirConnect-Synology/issues/104).

**Important: whether this affects your device is not predictable from its model or
platform alone.** A device's exposure to this depends on its _current_ DSM patch level,
not just its kernel version or Synology platform name - the same platform/kernel
combination that failed for one user in 2024 was directly re-tested on this project's
own hardware in 2026 and ran without issue, on the current DSM patch level for that
device. There's no static compatibility table that can answer this correctly for every
device and patch level, so none is provided here - and there is currently no automated
install-time check either (`preinst` is presently a no-op).

If you hit this:

1. Check your device's glibc version via SSH: `/lib64/libc.so.6 --version` (or
   `/lib/libc.so.6` on 32-bit devices).
2. Compare against [issue #63](https://github.com/eizedev/AirConnect-Synology/issues/63)
   for what's already known to fail/work at specific versions.
3. If the current package doesn't run, the [legacy DSM 5/6 line](ARCHITECTURES.md#older-dsm-56-devices)
   (pinned to an older AirConnect build with a lower minimum kernel/glibc requirement)
   may still work on your device - it's a separate, frozen package, install side-by-side
   or instead.
4. Still stuck? Open an [issue](https://github.com/eizedev/AirConnect-Synology/issues)
   with your device model, DSM version, and the glibc version from step 1.

## Playback issues after a Sonos firmware update

If AirPlay playback to Sonos broke after updating Sonos firmware to 15.2, update Sonos
again to 15.3 or later - this was a Sonos-side regression, fixed in a later Sonos
release. See [upstream issue #458](https://github.com/philippe44/AirConnect/issues/458)
if it's still happening on a current Sonos firmware.

## General issues

Open an [issue](https://github.com/eizedev/AirConnect-Synology/issues) if you're stuck.
Please include: your Synology device model, which package you downloaded, and both
logfiles (see [Logs](../README.md#logs) in the main README) or the relevant excerpts.

If `airupnp`/`aircast` are running with nothing unusual in the log, but playback itself
still doesn't behave as expected, that's more likely an AirConnect-the-program issue
than a packaging issue - consider opening an issue at the
[official AirConnect repository](https://github.com/philippe44/AirConnect/issues)
instead.

## Multicast and IGMP snooping/proxy

Most AirConnect problems trace back to local network configuration - both Chromecast and
Sonos/UPnP discovery **require multicast** to work. Make sure multicast is allowed along
the entire path:

> Chromecast/Sonos speaker ↔ (WLAN) router ↔ (switch/firewall ↔) the phone/computer
> you're using

Configure IGMP snooping and IGMP proxy correctly on your router, switches, and firewall.
For testing, try disabling IGMP snooping everywhere temporarily.

- **Players disappearing regularly** often means your router is filtering multicast
  packets. On an Asus AC-RT68U, for example: `echo 0 > /sys/class/net/br0/bridge/multicast_snooping`
  via SSH (doesn't persist across reboots).
- **UniFi networks** are a common source of multicast/discovery problems - see this
  [community guide](https://www.neilgrogan.com/ubnt-sonos/) for one documented fix.

More background in the official AirConnect repository:

- [Best practices for getting AirUPnP working in networks?](https://github.com/philippe44/AirConnect/issues/270)
- [Troubleshooting steps for airupnp AirPlay devices not appearing](https://github.com/philippe44/AirConnect/issues/217)
- [Devices disappear after ~1-2 minutes](https://github.com/philippe44/AirConnect/issues/189)
- [Devices found, but not being added](https://github.com/philippe44/AirConnect/issues/160)
- [Unable to connect to "device"](https://github.com/philippe44/AirConnect/issues/246)

## Debugging

### DSM 7

Change `AIRCAST_LOGLEVEL`/`AIRUPNP_LOGLEVEL` from `all=info` to `all=debug` in
[airconnect.conf](CONFIG.md#airconnectconf), then restart the package.

### DSM 5 and 6

Change the `-d all=info` parameter in `scripts/start-stop-status` to `-d all=debug`,
rebuild the package (see [Building from source](BUILD.md)), and reinstall it.
