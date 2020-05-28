# AirConnect package for Synology NAS and Synology Router

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/eizedev/AirConnect-Synology)](https://github.com/eizedev/AirConnect-Synology/releases/latest) [![GitHub All Releases](https://img.shields.io/github/downloads/eizedev/AirConnect-Synology/total)](https://github.com/eizedev/AirConnect-Synology/releases) [![GitHub issues](https://img.shields.io/github/issues-raw/eizedev/AirConnect-Synology)](https://github.com/eizedev/AirConnect-Synology/issues)

![AirConnect-Synology Logo](images/header.png)

A minimal Synology package for [AirConnect](https://github.com/philippe44/AirConnect).  
It allows you to use [AirPlay](https://en.wikipedia.org/wiki/AirPlay) to stream to **UPnP/Sonos** & **Chromecast** devices that do not natively support AirPlay.  

- [AirConnect package for Synology NAS and Synology Router](#airconnect-package-for-synology-nas-and-synology-router)
  - [Information](#information)
  - [How to install](#how-to-install)
    - [Download the pre-build Synology package](#download-the-pre-build-synology-package)
    - [Install via GUI (Package Center)](#install-via-gui-package-center)
    - [Install via command line](#install-via-command-line)
      - [Logfiles](#logfiles)
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
  - [Troubleshooting](#troubleshooting)
    - [Issues](#issues)
    - [Debugging](#debugging)
  - [License](#license)

## Information

Since the [original repository](https://github.com/bandesz/AirConnect-Synology) from [@bandesz](https://github.com/bandesz) was archived, I will try to provide the latest (and new) releases here regularly.  

- Updated the installation scripts to make them more robust to certain problems and also fixed a few bugs.
  - Also changed the build process and installation scripts with more validation and error handling.
- Adapted the documentation (this readme for now) to make it easier for new users to get started and to make everything a bit more understandable.
- Added new releases to fit the current AirConnect versions.
  - AirConnect-Synology releases will use the official AirConnect version + the current build date as tag/version (f.e. `0.2.25.0-20200511`)
- Added new pre-build synology packages that includes all current supported architectures and platforms
  - New pre-build: `ppc, ppc-static, arm`
  - Updated `armv7, armv8, x86` and `x86-64` to also support the newer (and older) synology hardware
  - Check [Download the pre-built Synology package](#download-the-pre-built-synology-package) for more information.  

I own multiple Synology NAS devices and the current Synology Router, as long as that is the case, I will also update the releases regularly.  
If a release is missing or does not work on your device, please open an [issue](https://github.com/eizedev/AirConnect-Synology/issues), then I will check this and deliver it to.

The credit goes of course still to [@bandesz](https://github.com/bandesz) for the initial work and [philippe44](https://github.com/philippe44) for the AirConnect application.  

## How to install

Every pre-build synology package in the [releases](https://github.com/eizedev/AirConnect-Synology/releases) section are including these two programs:

- `airupnp`
  - For **UPnP/Sonos players**
- `aircast`
  - For **Chromecast**

So you only need one package to support **UPnP**, **Sonos** and **Chromcast** devices.

### Download the pre-build Synology package

You can find the available packages under [releases](https://github.com/eizedev/AirConnect-Synology/releases) for these different architecture groups:

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
  - If the above **PowerPC** package will not work on your device, please download the latest ppc-static package.
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

You can view the logs by clicking on **View Log** on the packages page, or, if not available on your device, by using the [command line](#install-via-command-line).  

### Install via command line

- Connect to your NAS/Router via ssh ([How to login to DSM with root permission via SSH/Telnet](https://www.synology.com/en-global/knowledgebase/DSM/tutorial/General_Setup/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet))
- Copy over or download your release for [your architecture](#download-the-pre-built-synology-package)
  - For example, you can use (S)FTP to copy your files to your NAS ([How to access files on Synology NAS via FTP
](https://www.synology.com/en-global/knowledgebase/DSM/tutorial/File_Sharing/How_to_access_files_on_Synology_NAS_via_FTP)).
  - You can also copy your files to a shared folder (f.e. `home` -> `/volume1/home`) on your NAS and, after connecting via ssh, change to the shared folder directory.
- Change the path to the directory where you copied the package file (f.e. `home` -> `cd /volume1/home`).
- Run the following command based on your architecture and version `sudo synopkg install AirConnect-${ARCH}-${VERSION}.spk`
  - Example: `sudo synopkg install AirConnect-arm-0.2.24.7-20200417.spk`
- Start the **AirConnect** package with `sudo /usr/syno/bin/synopkg start AirConnect` or trough the Package Center
- Check the status of AirConnect with `sudo /usr/syno/bin/synopkg status AirConnect`
- The default installation directory is located here: `/var/packages/AirConnect/`
  - The binaries can be found in: `/var/packages/AirConnect/target/`

#### Logfiles

You can find the **synology dsm package logfile** at `/var/log/packages/AirConnect.log` (This logfile is used  from DSM/Synology for all installation/uninstallation/update purposes).  
You can find the **AirConnect application logfile** with `sudo /usr/syno/bin/synopkg log AirConnect` (Default: `/var/log/airconnect.log`).

You could also clone this repository on your synology device and build your package for your architecture locally, check [Build](#build) for more details.

## How it works

It runs the AirConnect processes with the following options tuned for sonos:

```bash
/volume1/@appstore/AirConnect/airupnp -b [synology device local ip]:49154 -l 1000:2000 -x "/volume1/@appstore/AirConnect/config.xml" -z -f "/var/log/airconnect.log" -d all=info  
/volume1/@appstore/AirConnect/aircast -b [synology device local ip] -l 1000:2000 -x "/volume1/@appstore/AirConnect/config-cast.xml" -z -f "/var/log/airconnect.log" -d all=info
```

The process is running with a low-privilege user.

The processes will only recognise your devices if they are bound to the appropriate local network IP, but this is not trivial as there are various Synology devices and network setups.  
The start script will check all your local network interfaces (with ip 192.168.* or 10.* or 172.16.* - 172.31.*) and checks if the airupnp/aircast processes add any devices (based on the logs).

It there are no devices added in **10 seconds** it will try the next interface (if more interfaces are available).  
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

By default the config file will **not** being used as long as the file is not created. The file is **not** created by default.  

- Config File for airupnp
  - `/volume1/@appstore/AirConnect/config.xml`
- Config File for aircast
  - `/volume1/@appstore/AirConnect/config-cast.xml`

You can create each of these files manually or a reference version can be generated using the `-i [config file name]` command line parameter.
For the following example i am using the default configuration you can find above in the [How it works](#how-it-works) section. I am just change the `-x` parameter with the `-i` parameter.

Change the ip and parameters for your needs:

Example:

```bash
/volume1/@appstore/AirConnect/airupnp -b 192.168.1.249:49154 -l 1000:2000 -i /volume1/@appstore/AirConnect/config.xml -z -f /var/log/airconnect.log -d all info -d main info
```

After running this command, airupnp will be started until all needed information and devices are gathered, stopped and the resulted configuration will be written to the defined config file.

### Player specific settings, hints and tips

See the original [Player specific hints and tips](https://github.com/philippe44/AirConnect#player-specific-hints-and-tips) from [philippe44](https://github.com/philippe44) for more information.

#### Sonos

The upnp version is often used with Sonos players. When a Sonos group is created, only the master of that group will appear as an AirPlay player and others will be removed if they were already detected. If the group is later split, then individual players will re-appear.

You need to use the Sonos native application for grouping / ungrouping.

When changing volume of a group, each player's volume is changed trying to respect the relative values. It's not perfect and still under test now. To reset all volumes to the same value, simply move the cursor to 0 and then to the new value. All players will have the same volume then. You need to use the Sonos application to change individual volumes.

To identify your Sonos players, pick an identified IP address, and visit the Sonos status page in your browser, like `http://192.168.1.126:1400/support/review`. Click `Zone Players` and you will see the identifiers for your players in the `UUID` column.

#### Bose SoundTouch

[@chpusch](https://github.com/chpusch) has found that Bose SoundTouch work well including synchronisation (as for Sonos, you need to use Bose's native application for grouping / ungrouping). I don't have a SoundTouch system so I cannot do the level of slave/master detection I did for Sonos

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

After that you can start the build process by running `shellcheck` or directly with the build steps.

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

## Troubleshooting

### Issues

If you have a problem installing or using one of these package and/or are stuck, please open an [issue](https://github.com/eizedev/AirConnect-Synology/issues).  
It would be very helpful if you tell me the synology device you are using, the package you have downloaded and upload the two logfiles mentioned in the [Logfiles](#logfiles) section or include the important parts from the logfiles in the issue.

### Debugging

If you want to see more logs then change the `-d all=info` parameter in `scripts/start-stop-status` to `-d all=debug` and rebuild the package, then [install it again](#install-via-command-line).

## License

See [LICENSE](https://github.com/philippe44/AirConnect/blob/master/LICENSE).
