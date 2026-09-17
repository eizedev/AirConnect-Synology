#!/bin/sh

tee "$SYNOPKG_TEMP_LOGFILE" <<EOF
[
    {
        "step_title": "Uninstall AirConnect",
        "items": [
            {
                "type": "multiselect",
                "desc": "Optional cleanup",
                "subitems": [
                    {
                        "key": "pkgwizard_delete_shared_folder",
                        "desc": "Delete the contents of the \"airconnect\" shared folder (linked config/log, plus anything else placed there) - off by default",
                        "defaultValue": false
                    }
                ]
            },
            {
                "desc": "Leave this unchecked to keep the shared folder and its contents, in case you want to reinstall later or keep the logs. This cannot be undone once checked. Note: this empties the folder but can't remove the (now unused) shared folder entry itself - Synology doesn't let packages do that; see the documentation for the manual step if you want it fully gone."
            }
        ]
    }
];
EOF

exit 0
