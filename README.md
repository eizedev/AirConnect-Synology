# AirConnect package for Synology NAS and Synology Router

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/eizedev/AirConnect-Synology)](https://github.com/eizedev/AirConnect-Synology/releases/latest) [![GitHub All Releases](https://img.shields.io/github/downloads/eizedev/AirConnect-Synology/total)](https://github.com/eizedev/AirConnect-Synology/releases) [![GitHub issues](https://img.shields.io/github/issues-raw/eizedev/AirConnect-Synology)](https://github.com/eizedev/AirConnect-Synology/issues)

A minimal Synology package for [AirConnect](https://github.com/philippe44/AirConnect).  
It allows you to use AirPlay to stream to UPnP/Sonos & Chromecast devices that do not natively support AirPlay.

- [AirConnect package for Synology NAS and Synology Router](#airconnect-package-for-synology-nas-and-synology-router)
  - [Information](#information)
  - [How to install](#how-to-install)
    - [Download the pre-built Synology package](#download-the-pre-built-synology-package)
    - [Install via GUI (Package Center)](#install-via-gui-package-center)
    - [Install via command line](#install-via-command-line)
  - [How it works](#how-it-works)
    - [Configuration](#configuration)
    - [Player specific settings, hints and tips](#player-specific-settings-hints-and-tips)
      - [Sonos](#sonos)
      - [Bose SoundTouch](#bose-soundtouch)
      - [Pioneer/Phorus/Play-Fi](#pioneerphorusplay-fi)
  - [Build](#build)
    - [Run shellcheck (optional)](#run-shellcheck-optional)
    - [Build packages for all architectures](#build-packages-for-all-architectures)
    - [Build a package for a specific architecture](#build-a-package-for-a-specific-architecture)
  - [Debugging](#debugging)
  - [License](#license)

## Information

Since the [original repository](https://github.com/bandesz/AirConnect-Synology) from [@bandesz](https://github.com/bandesz) was archived, I will try to provide the latest releases here regularly and have updated the scripts and just provided the current release.  
I have also updated the scripts, readme, releases and a few other files with more validation and error handling.  
I own multiple Synology NAS Systems and the current Synology Router, as long as that is the case, I will also update the releases regularly.

If a release is missing, please open an [issue](https://github.com/eizedev/AirConnect-Synology/issues), then I will deliver it to.

The credit goes of course still to [@bandesz](https://github.com/bandesz) for the inital work and [philippe44](https://github.com/philippe44) for the AirConnect application.  

## How to install

### Download the pre-built Synology package

You can find the available packages under [Releases](https://github.com/eizedev/AirConnect-Synology/releases) for six different architecture groups:

- **ARMv5**: 88f6282 88f6281 88f628x
  - Please download: `AirConnect-arm5-${VERSION}`
- **ARMv7**: ipq806x ipq806x armada370 armadaxp armada375 armada38x alpine alpine4k monaco comcerto2k hi3535 dakota ipq806x northstarplus
  - Please download: `AirConnect-arm-${VERSION}`
- **ARMv8**: rtd1296 armada37xx
  - Please download: `AirConnect-aarch64-${VERSION}`
- **PowerPC**: qoriq Ppc853x
  - Please download: `AirConnect-ppc-${VERSION}`
- **PowerPC Static**: noarch qoriq Ppc853x
  - Please download: `AirConnect-ppc-static-${VERSION}`
  - If the above **PowerPC** package will work on your device, please download the latest ppc-static package.
    - The static package includes "static" binaries, that means, it includes binaries that have no external library dependencies.
- **Intel - 32-bit**: x86 cedarview bromolow evansport avoton braswell broadwell apollolake dockerx64 kvmx64 denverton grantley broadwellnk Broadwellntbap
  - Please download: `AirConnect-x86-${VERSION}`
- **Intel - 64-bit (DSM 6.0+)**: x86_64 x64 cedarview bromolow avoton braswell broadwell apollolake dockerx64 kvmx64 denverton grantley broadwellnk Broadwellntbap
  - Please download: `AirConnect-x86-64-${VERSION}`


You can check which architecture you have [here](https://www.synology.com/en-us/knowledgebase/DSM/tutorial/Compatibility_Peripherals/What_kind_of_CPU_does_my_NAS_have).

For the Synology **Routers** you should use the **ARM** (ARMv7 - dakota, ipq806x, northstarplus) version.

### Install via GUI (Package Center)

- Open the Package Center app.
- As this package is not an official Synology package you may have to
  - **Allow packages from any publisher**
    - Go to **Settings** and set the **Trust Level** to "**Any publisher**".
- Click on **Manual Install** and upload the package you just downloaded.

Don't forget to **change back** the **Trust level** to "Synology Inc." for additional security.

You can see the logs by clicking on **View Log** on the packages page, or, if not available on your device, by using the [command line](#install-via-command-line).  

### Install via command line

- Connect to your NAS/Router via ssh
- Copy over or download your release for [your architecture](#download-the-pre-built-synology-package)
- Run the following command based on your architecture and version `sudo synopkg install AirConnect-${ARCH}-${VERSION}.spk`
  - Example: `sudo synopkg install AirConnect-arm-0.2.24.7-20200417.spk`
- Start the **AirConnect** package with `sudo /usr/syno/bin/synopkg start AirConnect` or trough the Package Center
- Check the status of AirConnect with `sudo /usr/syno/bin/synopkg status AirConnect`
- The default installation directory is located here: `/var/packages/AirConnect/`
  - The binaries can be found in: `/var/packages/AirConnect/target/`

You can find the synology dsm package logfile at `/var/log/packages/AirConnect.log`.  
You can find the application logfile with `sudo /usr/syno/bin/synopkg log AirConnect` (Default: `/var/log/airconnect.log`).

You could also clone this repository on your synology device and build your package for your architecture locally, check [Build](#build) for more details.

## How it works

It runs the AirConnect processes with the following options tuned for sonos:

```bash
/volume1/@appstore/AirConnect/airupnp -b [synology device local ip]:49154 -l 1000:2000 -x /volume1/@appstore/AirConnect/config.xml -z -f /var/log/airconnect.log -d all info -d main info

/volume1/@appstore/AirConnect/aircast -b [synology device local ip] -l 1000:2000 -x /volume1/@appstore/AirConnect/config-cast.xml -z -f /var/log/airconnect.log -d all info -d main info
```

The process is running with a low-privilege user.

The processes will only recognise your devices if they are bound to the appropriate local network IP, but this is not trivial as there are various Synology devices and network setups.  
The start script will check all your local network interfaces (with ip 192.168.* or 10.* or 172.16.* - 172.31.*) and checks if the airupnp/aircast processes add any devices (based on the logs).

It there are no devices added in **10 seconds** it will try the next interface.  
For the automatic IP discovery to work you should have at least one UPnP/Sonos/Chromecast device on your network.

If the start script is not able to find the right IP automatically you can fix it in `scripts/start-stop-status` by setting your own local IP (of your nas/router) and building your own package.

Look for the following lines:

```bash
# If you want to start the airconnect processes on a specific IP please uncomment the following lines
# and set your own local IP address:
#
# start_airconnect_on_ip "1.2.3.4" || true
# return  0
```

Alternatively you can open an issue and include your network interface list and your local IP and i will extend the default network interfaces filter with your list.

### Configuration

If you would like to tweak the AirConnect configuration you can also use the AirConnect configuration file.
> Before continuing please check [official readme](https://github.com/philippe44/AirConnect#config-file-parameters) for more information. I'm not going to explain how it generally works here.

By default the config file will **not** being used as long as the file is not created. The file are **not** created by default.  

- Config File for airupnp
  - `/volume1/@appstore/AirConnect/config.xml`
- Config File for aircast
  - `/volume1/@appstore/AirConnect/config-cast.xml`

You can create each of these file manually or a reference version can be generated using the `-i [config file name]` command line parameter.
For this example i am using the default configuration you can find above in the [How it works](#how-it-works) section. I am just change the `-x` paramter with the `-i` parameter.
Change the ip and parameters for your needs:

Example:

```bash
/volume1/@appstore/AirConnect/airupnp -b 192.168.1.249:49154 -l 1000:2000 -i /volume1/@appstore/AirConnect/config.xml -z -f /var/log/airconnect.log -d all info -d main info
```

After running this command, the airupnp will be started until all needed information and devices are gathered and written to the defined config file.

### Player specific settings, hints and tips

See the original [Player specific hints and tips](https://github.com/philippe44/AirConnect#player-specific-hints-and-tips) from [philippe44](https://github.com/philippe44) for more information.

#### Sonos

The upnp version is often used with Sonos players. When a Sonos group is created, only the master of that group will appear as an AirPlay player and others will be removed if they were already detected. If the group is later split, then individual players will re-appear.

You need to use the Sonos native application for grouping / ungrouping.

When changing volume of a group, each player's volume is changed trying to respect the relative values. It's not perfect and stil under test now. To reset all volumes to the same value, simply move the cursor to 0 and then to the new value. All players will have the same volume then. You need to use the Sonos application to change individual volumes.

To identify your Sonos players, pick an identified IP address, and visit the Sonos status page in your browser, like `http://192.168.1.126:1400/support/review`. Click `Zone Players` and you will see the identifiers for your players in the `UUID` column.

#### Bose SoundTouch

[@chpusch](https://github.com/chpusch) has found that Bose SoundTouch work well including synchonisation (as for Sonos, you need to use Bose's native application for grouping / ungrouping). I don't have a SoundTouch system so I cannot do the level of slave/master detection I did for Sonos

#### Pioneer/Phorus/Play-Fi

Check the [Configuration](#configuration) section on how to apply the below tuning to the configuration.

Some of these speakers only support mp3 and require a modified `ProtocolInfo` to stream correctly. This can be done by editing the [config file](#configuration) and changing `<codec>flac</codec>` to `<codec>mp3</codec>` and replacing the `<mp3>..</mp3>` line with:

```html
<mp3>http-get:*:audio/mpeg:DLNA.ORG_PN=MP3;DLNA.ORG_OP=00;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=0d500000000000000000000000000000</mp3>
```

## Build

You need to install the following packages on your distribution:

- make
- shellcheck

After that you can start by running the shellcheck or directly with the build.

### Run shellcheck (optional)

```bash
make shellcheck
```

### Build packages for all architectures

```bash
make clean build-all
```

### Build a package for a specific architecture

```bash
ARCH=arm make clean build
```

Possible values for **ARCH**: `arm, aarch64, arm5, ppc, x86, x86-64`

You can find the built packages in the **dist** directory.

## Debugging

If you want to see more logs then change the `-d all=info` parameter in `scripts/start-stop-status` to `-d all=debug` and rebuild the package, then [install it again](#install-via-command-line).

## License

See [LICENSE](https://github.com/philippe44/AirConnect/blob/master/LICENSE).
