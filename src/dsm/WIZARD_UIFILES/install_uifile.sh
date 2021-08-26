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
    }
];
EOF

exit 0
