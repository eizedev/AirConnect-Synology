# Configuration reference

Full `airconnect.conf` option reference, `config.xml`/`config-cast.xml` details,
upstream command-line arguments, and player-specific tuning. For the short version (how
to reach these files at all), see
[Editing files from your PC](../README.md#editing-files-from-your-pc) in the main README.

## airconnect.conf

> Only available for DSM 7 packages.
>
> Upgrading an existing install never changes your `airconnect.conf`. To reset it to
> defaults, uninstall and reinstall, or copy the values below into your file by hand.

Located at `/volume1/@appstore/AirConnect/airconnect.conf` (adjust `/volume1` if your
package is installed on a different volume). Stop the package before editing it, and
restart it afterward if you edited it while running.

Default values:

```bash
AIRCAST_ENABLED=1
AIRCAST_LATENCY="50:500"
AIRCAST_LOGLEVEL="all=info"
AIRUPNP_ENABLED=1
AIRUPNP_LATENCY="50:500"
AIRUPNP_LOGLEVEL="all=info"
AIRUPNP_CONTENTLENGTH_MODE=0
AIRUPNP_PORT=49154
AIRUPNP_PORTRANGE="49155:128"
FILTER_AIRPLAY2_DEVICES="<NULL>,S1,S3,S5,S9,S12,ZP80,ZP90,S15,ZP100,ZP120,1.0,LibreWireless,Fitzwilliam,2.2.6,AllShare1.0"
SYNO_IP="<your synology ip>"
```

| Option                       | Values                             | Mandatory     | Description                                                                                                                                                                                                     |
| ---------------------------- | ---------------------------------- | ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `AIRCAST_ENABLED`            | `0` or `1`                         | Yes           | Enable/disable Chromecast support (`aircast`)                                                                                                                                                                   |
| `AIRCAST_LATENCY`            | `[rtp][:http][:f]`                 | No            | RTP and HTTP latency (ms); `:f` forces silence fill                                                                                                                                                             |
| `AIRCAST_LOGLEVEL`           | `<log>=<level>`                    | Yes           | `log`: `all,raop,main,util,cast` — `level`: `error,warn,info,debug,sdebug`                                                                                                                                      |
| `AIRUPNP_ENABLED`            | `0` or `1`                         | Yes           | Enable/disable UPnP/Sonos support (`airupnp`)                                                                                                                                                                   |
| `AIRUPNP_LATENCY`            | `[rtp][:http][:f]`                 | No            | RTP and HTTP latency (ms); `:f` forces silence fill                                                                                                                                                             |
| `AIRUPNP_LOGLEVEL`           | `<log>=<level>`                    | Yes           | `log`: `all,raop,main,util,upnp` — `level`: `error,warn,info,debug,sdebug`                                                                                                                                      |
| `AIRUPNP_CONTENTLENGTH_MODE` | `-3`, `-1`, or `0`                 | Yes           | HTTP content-length mode (`-3`: chunked, `-1`: none, `0`: fixed)                                                                                                                                                |
| `AIRUPNP_PORT`               | e.g. `49154`                       | Yes (airupnp) | Port `airupnp` starts on                                                                                                                                                                                        |
| `AIRUPNP_PORTRANGE`          | `<port>:<count>`, e.g. `49155:128` | No            | Fixed port range for the RTP/HTTP streams `airupnp` opens per device - useful for firewall rules ([#142](https://github.com/eizedev/AirConnect-Synology/issues/142)). Leave empty for random OS-assigned ports. |
| `FILTER_AIRPLAY2_DEVICES`    | comma-separated model list         | No            | See [Supported UPnP speakers](#supported-upnp-speakers)                                                                                                                                                         |
| `SYNO_IP`                    | e.g. `192.168.1.100`               | Yes           | IP `aircast`/`airupnp` bind to                                                                                                                                                                                  |

Options marked `Mandatory = Yes` must exist in the file (can be empty); `No` options are
truly optional. Don't delete an option you don't want to use - just leave its value
empty, e.g. `FILTER_AIRPLAY2_DEVICES=`.

## How the processes are actually started

For reference, here's what the package runs by default (Sonos-tuned defaults):

```bash
/volume1/@appstore/AirConnect/airupnp -b [synology device local ip]:49154 -l 50:500 -g 0 -x "/volume1/@appstore/AirConnect/config.xml" -o "<NULL>,S1,S3,S5,S9,S12,ZP80,ZP90,S15,ZP100,ZP120,1.0,LibreWireless,Fitzwilliam,2.2.6,AllShare1.0" -z -f "/volume1/@appstore/AirConnect/log/airconnect.log" -d all=info
```

```bash
/volume1/@appstore/AirConnect/aircast -b [synology device local ip] -l 50:500 -x "/volume1/@appstore/AirConnect/config-cast.xml" -z -f "/volume1/@appstore/AirConnect/log/airconnect.log" -d all=info
```

Both processes run as the low-privilege `airconnect` user, not root.

## config.xml / config-cast.xml

These are the upstream AirConnect binaries' own config files (`airupnp` and `aircast`
respectively) - a different, more advanced mechanism than `airconnect.conf`, for options
`airconnect.conf` doesn't expose. Not created by default; the binaries run fine without
them.

- `airupnp`: `/volume1/@appstore/AirConnect/config.xml`
- `aircast`: `/volume1/@appstore/AirConnect/config-cast.xml`

(Both always reachable via SSH regardless of settings; also reachable over SMB at
`/volume1/airconnect/config.xml` / `config-cast.xml` if you checked **"Enable
shared-folder links"** - see
[Editing files from your PC](../README.md#editing-files-from-your-pc).)

> If you want the device list in `config.xml` (rather than `airconnect.conf`'s built-in
> filter) to decide which speakers `airupnp` picks up, disable the default filter first:
> `FILTER_AIRPLAY2_DEVICES=` in `airconnect.conf` - the built-in filter otherwise
> overrides anything in `config.xml`.

Generate a starting point by running the binary once with `-i` instead of `-x` (change
the ip/parameters for your needs first):

```bash
/volume1/@appstore/AirConnect/airupnp -b 192.168.1.249:49154 -l 50:500 -g 0 -i "/volume1/@appstore/AirConnect/config.xml" -o "<NULL>,S1,S3,S5,S9,S12,ZP80,ZP90,S15,ZP100,ZP120,1.0,LibreWireless,Fitzwilliam,2.2.6,AllShare1.0" -z -f "/volume1/@appstore/AirConnect/log/airconnect.log" -d all=info
```

This runs `airupnp` until it's discovered your devices, then stops and writes the
resulting config to the file you named. Check the
[official AirConnect readme](https://github.com/philippe44/AirConnect#config-file-parameters)
for the file's own format - this project doesn't re-document it.

## Command-line arguments

Real `--help`-equivalent usage output, read directly from the AirConnect 1.11.3 source
(`airupnp.c`/`aircast.c`) rather than an older cached copy - the previous version of this
table was from `v1.6.3` and had drifted (missing `airupnp`'s `-S` flag entirely, and an
outdated `-c` format list on both binaries).

### airupnp

```text
v1.11.3
See -t for license terms
Usage: [options]
  -b <ip|iface>[:<port>] network interface or interface and UPnP port to use
  -a <port>[:<count>]    set inbound port and range for RTP and HTTP
  -c <mp3[:<rate>]|aac[:<rate>]|flac[:0..9][/1152...16384]|wav|pcm>  audio format send to player
  -g <-3|-1|0>           HTTP content-length mode (-3:chunked, -1:none, 0:fixed)
  -S <broadcast|track|radio>  how a Sonos is told to present the stream (default broadcast)
  -u <version>           set the maximum UPnP version for search (default 1)
  -x <config file>       read config from file (default is ./config.xml)
  -i <config file>       discover players, save <config file> and exit
  -I                     auto save config at every network scan
  -l <[rtp][:http][:f]>  RTP and HTTP latency (ms), ':f' forces silence fill
  -r                     let timing reference drift (no click)
  -f <logfile>           write debug to logfile
  -p <pid file>          write PID in file
  -N <format>            transform device name using C format (%s=name)
  -m <n1,n2...>          exclude devices whose model include tokens
  -n <m1,m2,...>         exclude devices whose name includes tokens
  -o <m1,m2,...>         include only listed models; overrides -m and -n (use <NULL> if player don't return a model)
  -d <log>=<level>       set logging level, logs: all|raop|main|util|upnp, level: error|warn|info|debug|sdebug
  -z                     daemonize
  -Z                     NOT interactive
  -k                     immediate exit on SIGQUIT and SIGTERM
  -t                     license terms
  --noflush              ignore flush command (wait for teardown to stop)

Build options: LINUX
```

### aircast

```text
v1.11.3
See -t for license terms
Usage: [options]
  -b <ip|iface>         network address or interface to bind to
  -a <port>[:<count>]   set inbound port and range for RTP and HTTP
  -c <mp3[:<rate>]|aac[:<rate>]|flac[:0..9][/1152...16384]|wav>  audio format send to player
  -v <0..1>             group MediaVolume factor
  -x <config file>      read config from file (default is ./config.xml)
  -i <config file>      discover players, save <config file> and exit
  -I                    auto save config at every network scan
  -N <format>           transform device name using C format (%s=name)
  -l <[rtp][:http][:f]> RTP and HTTP latency (ms), ':f' forces silence fill
  -r                    let timing reference drift (no click)
  -f <logfile>          write debug to logfile
  -p <pid file>         write PID in file
  -d <log>=<level>      set logging level, logs: all|raop|main|util|cast, level: error|warn|info|debug|sdebug
  -z                    daemonize
  -Z                    NOT interactive
  -k                    immediate exit on SIGQUIT and SIGTERM
  -t                    license terms
  --noflush             ignore flush command (wait for teardown to stop)

Build options: LINUX
```

## Supported UPnP speakers

> On DSM 7 you can just change `FILTER_AIRPLAY2_DEVICES` in
> [airconnect.conf](#airconnectconf) - remove it entirely to allow all AirPlay2 devices.

To speed up discovery and avoid double-listing speakers that already natively support
AirPlay, this package only surfaces the models below by default
(`-o <NULL>,S1,S3,...`) - any Sonos/UPnP speaker with native AirPlay/AirPlay2 support is
filtered out, and only the ones in this list are exposed through `airupnp`.

| Model number            | Friendly name                       | Comment (Sonos series ID, etc.) |
| ----------------------- | ----------------------------------- | ------------------------------- |
| `S1`                    | Sonos Play:1 (old model)            | A101                            |
| `S3`                    | Sonos Play:3                        | A100                            |
| `S5`                    | Sonos Play:5                        | P100                            |
| `S9`                    | Sonos Playbar                       | A100                            |
| `S12`                   | Sonos Play:1                        | A200                            |
| `S15`                   | Sonos Connect                       | S100                            |
| `ZP80`                  | Sonos Connect (old model)           | C100                            |
| `ZP90`                  | Sonos Connect                       | C100                            |
| `ZP100`                 | Sonos Connect:Amp (old model)       | P100                            |
| `ZP120`                 | Sonos Connect:Amp                   | P100                            |
| `1.0` / `LibreWireless` | LibreWireless-based speakers        | LibreSyncDMR                    |
| `Fitzwilliam`           | Fitzwilliam                         | Fitzwilliam                     |
| `2.2.6`                 | Devialet Expert Pro 140             | Devialet Expert Pro             |
| `AllShare1.0`           | Samsung HW-N950                     | Samsung HW-N950 soundbar        |
| `<NULL>`                | All speakers without a model number |                                 |

Missing a device that should be here? Open an
[issue](https://github.com/eizedev/AirConnect-Synology/issues) with the product name
(model name/number) and it'll be added to the default filter.

### Finding your speaker's model number

1. Install the Synology diagnostic tools via SSH as root: `synogear install` (see
   [FAQ-synogear](https://github.com/SynoCommunity/spksrc/wiki/FAQ-synogear); also
   installs several other useful busybox/Linux commands).
2. Capture the device's SSDP announcement (replace `en0` with your network interface;
   wait a few seconds for devices to announce themselves):

   ```bash
   sudo tcpdump -vv -A -s 0 -i en0 host 239.255.255.250 and port 1900 | grep LOCATION
   ```

3. Take the IP from the `LOCATION` URL you captured, then fetch its device description
   and grep for the model number:

   ```bash
   curl http://192.168.1.122:1400/xml/device_description.xml | grep modelNumber
   ```

   (`S12` in this example is a Sonos Play:1.)

## Player-specific hints and tips

> See also the
> [official AirConnect hints and tips](https://github.com/philippe44/AirConnect#player-specific-hints-and-tips)
> from [philippe44](https://github.com/philippe44) - not re-documented here.

### Sonos

When a Sonos group is created, only the group's master appears as an AirPlay player;
others drop out of the list until the group is split again. Use the Sonos app itself for
grouping/ungrouping - this package doesn't control that.

Changing a group's volume adjusts each player's volume trying to preserve relative
levels (imperfect, still being refined upstream). To reset all players to the same
volume, move the volume slider to 0 and back up to the target value.

To find a player's UUID: visit `http://<player-ip>:1400/support/review` in a browser,
then check `Zone Players`.

### Bose SoundTouch

Reported working well, including synchronization (same as Sonos - use Bose's own app for
grouping/ungrouping). Not independently verified by this project - no SoundTouch
hardware available to test the same level of master/slave detection done for Sonos.

### Pioneer/Phorus/Play-Fi

Some of these only support MP3 and need a modified `ProtocolInfo` to stream correctly.
In your [config.xml](#configxml--config-castxml), change `<codec>flac</codec>` to
`<codec>mp3</codec>` and replace the `<mp3>...</mp3>` line with:

```xml
<mp3>http-get:*:audio/mpeg:DLNA.ORG_PN=MP3;DLNA.ORG_OP=00;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=0d500000000000000000000000000000</mp3>
```
