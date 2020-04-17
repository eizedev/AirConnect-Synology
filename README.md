# AirConnect package for Synology NAS and Synology Router

[![Latest release](https://img.shields.io/github/v/release/eizedev/AirConnect-Synology)](https://github.com/eizedev/AirConnect-Synology/releases/latest)

A minimal Synology package for [AirConnect](https://github.com/philippe44/AirConnect).  
It allows you to use AirPlay to stream to UPnP/Sonos & Chromecast devices.

- [AirConnect package for Synology NAS and Synology Router](#airconnect-package-for-synology-nas-and-synology-router)
  - [Information](#information)
  - [How to install](#how-to-install)
    - [Download the pre-built Synology package](#download-the-pre-built-synology-package)
    - [Install via GUI (Package Center)](#install-via-gui-package-center)
    - [Install via command line](#install-via-command-line)
  - [How it works](#how-it-works)
  - [Build](#build)
    - [Run shellcheck (optional)](#run-shellcheck-optional)
    - [Build packages for all architectures](#build-packages-for-all-architectures)
    - [Build a package for a specific architecture](#build-a-package-for-a-specific-architecture)
  - [Debugging](#debugging)
  - [License](#license)

## Information

Since the [original repository](https://github.com/bandesz/AirConnect-Synology) from [@bandesz](https://github.com/bandesz) was archived, I will try to provide the latest releases here regularly and have updated the scripts and just provided the current release.  
I own multiple Synology NAS Systems and the current Synology Router, as long as that is the case, I will also update the releases regularly.

If a release is missing, please open an [issue](https://github.com/eizedev/AirConnect-Synology/issues), then I will deliver it to.

The credit goes of course still to [@bandesz](https://github.com/bandesz) and [philippe44](https://github.com/philippe44).  

## How to install

### Download the pre-built Synology package

You can find the available packages under [Releases](https://github.com/eizedev/AirConnect-Synology/releases) for four different architecture groups:

- **ARMv7**: ipq806x armada370 armadaxp armada375 armada38x alpine alpine4k monaco comcerto2k
- **ARMv8**: rtd1296
- **Intel - 32-bit**: x86 cedarview bromolow evansport avoton braswell broadwell apollolake
- **Intel - 64-bit (DSM 6.0+)**: x86_64

You can check which architecture you have [here](https://www.synology.com/en-us/knowledgebase/DSM/tutorial/Compatibility_Peripherals/What_kind_of_CPU_does_my_NAS_have).

For the Synology Routers you should use the ARM version.

### Install via GUI (Package Center)

Open the Package Center app.

As this package is not an official Synology package you may have to **allow packages from any publisher**. Go to **Settings** and set the **Trust Level** to "**Any publisher**".

Click on **Manual Install** and upload the package you just downloaded.

Don't forget to **change back** the **Trust level** to "Synology Inc." for additional security.

You can see the error logs by clicking on **View Log** on the package's page.  

### Install via command line

- Connect to your NAS/Router via ssh
- Copy over or download your release for [your architecture](#download-the-pre-built-synology-package)
- Run the following command based on your architecture and version `sudo synopkg install AirConnect-${ARCH}-${VERSION}.spk`
  - Example: `sudo synopkg install AirConnect-arm-0.2.24.7-20200417.spk`
- Start the **AirConnect** package with `/usr/syno/bin/synopkg start AirConnect` or trough the Package Center
- Check the status of AirConnect with `/usr/syno/bin/synopkg status AirConnect`
- You can find the logfile with `/usr/syno/bin/synopkg log AirConnect` (Default: `/tmp/airconnect.log`)

You could also clone this repository on your synology device and build your package for your distribution locally, check [Build](#build) for more details.

## How it works

It runs the AirConnect processes with the following options:

```bash
airupnp -b [router local ip]:49154 -z -l 1000:2000 -f /tmp/airupnp.log -d all=error -d main=info

aircast -b [router local ip] -z -l 1000:2000 -f /tmp/aircast.log -d all=error -d main=info
```

The process is running with a low-privilege user.

The processes will only recognise your devices if they are bound to the appropriate local network IP, but this is not trivial as there are various Synology devices and network setups.  
The start script will check all your local network interfaces (with ip 192.168.* or 10.* or 172.16.* - 172.31.*) and checks if the airupnp/aircast processes add any devices (based on the logs).  
It there are no devices added in 5 seconds it will try the next interface. For the automatic IP discovery to work you should have at least one UPnP/Sonos/Chromecast device on your network.

If the start script is not able to find the right IP automatically you can fix it in `scripts/start-stop-status` by setting your own local IP (of your nas/router) and building your own package.

Look for the following lines:

```bash
# If you want to start the airconnect processes on a specific IP please uncomment the following lines
# and set your own local IP address:
#
# start_airconnect_on_ip "1.2.3.4" || true
# return  0
```

Alternatively you can open an issue and include your network interface list and your local IP.

## Build

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

Possible values for **ARCH**: `arm, aarch64, x86, x86-64`

You can find the built packages in the **dist** directory.

## Debugging

If you want to see more logs then change the `-d all=error` parameter in `scripts/start-stop-status` and rebuild the package, then [install it again](#install-via-command-line).

## License

See [LICENSE](https://github.com/philippe44/AirConnect/blob/master/LICENSE).
