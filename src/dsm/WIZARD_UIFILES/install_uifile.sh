#!/bin/sh

SYNO_IP=$(ip -o route get to 1.0.0.0 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
#ip -4 -o addr show dev `netstat -rn | awk '/^0.0.0.0/ {thif=substr($0,74,10); print thif;} /^default.*UG/ {thif=substr($0,65,10); print thif;}'`| awk '{split($4,a,"/");print a[1]}'

tee "$SYNOPKG_TEMP_LOGFILE" <<EOF
[
    {
        "step_title": "Which AirConnect program(s) do you want to install?",
        "items": [
            {
                "type": "singleselect",
                "desc": "Choose Installation Type:",
                "subitems": [
                    {
                        "key": "pkgwizard_binaries_both",
                        "desc": "(Default) airupnp & aircast",
                        "defaultValue": true
                    },
                    {
                        "key": "pkgwizard_binaries_airupnp",
                        "desc": "Only airupnp",
                        "defaultValue": false
                    },
                    {
                        "key": "pkgwizard_binaries_aircast",
                        "desc": "Only aircast",
                        "defaultValue": false
                    }
                ]
            },
            {
                "desc": "<strong style='color:red'>Airupnp</strong> = Needed for Sonos and other UPnP speakers"
            },
            {
                "desc": "<strong style='color:red'>Aircast</strong> = Needed for Chromecast devices"
            },
            {
                "desc": "Please refer to the <a target='_blank' href='https://github.com/eizedev/AirConnect-Synology#readme'>documentation</a> in case of any problems/questions"
            }
        ]
    },
    {   
        "step_title": "Connection properties",
        "items": [
	        {
                "type": "textfield",
                "desc": "IP address on which airupnp/aircast will be started on (Default: Synology primary ip)",
                "subitems": [
                    {
                        "key": "pkgwizard_ip",
                        "desc": "IP of your synology device",
                        "defaultValue": "$SYNO_IP",
                        "validator": {
                            "allowBlank": false
                        }
                    }
                ]
	        },
	        {
                "type": "textfield",
                "desc": "Port for airupnp (will be ignored if airupnp is not specified in installation type)",
                "subitems": [
                    {   
                        "key": "pkgwizard_airupnp_port",
                        "desc": "Port for airupnp",
                        "defaultValue": "49154",
                        "validator": {
                            "allowBlank": false
                        }
                    }
                ]
            }
        ]
    },
    {
        "step_title": "Optional: Shared folder for GUI access",
        "items": [
            {
                "type": "multiselect",
                "desc": "Link config.xml/config-cast.xml, airconnect.conf and the log into a shared folder reachable over a network share (SMB) - lets you place a custom config.xml, edit airconnect.conf, or check the log from your computer without SSH. Most installs never need this - the defaults are already tuned to just work. Need something else made configurable here instead? Please open an issue.",
                "subitems": [
                    {
                        "key": "pkgwizard_create_shared_folder",
                        "desc": "Enable shared-folder links (off by default)",
                        "defaultValue": false
                    }
                ]
            },
            {
                "desc": "<strong style='color:red'>Note:</strong> works over SMB only - map the shared folder from Windows, Mac, or Linux (e.g. smb://&lt;your-nas&gt;/airconnect). Not supported via File Station (can't display symlinks) or AFP (no equivalent setting). You also need to enable 'allow symlinks' under <em>Control Panel - File Services - SMB - Advanced Settings</em> on your Synology device - a device-wide setting, not specific to this package. See the <a target='_blank' href='https://github.com/eizedev/AirConnect-Synology#readme'>documentation</a> for details and a screenshot. Leave this off if you're unsure - you can always reach these files via SSH instead."
            }
        ]
    }
];
EOF

exit 0
