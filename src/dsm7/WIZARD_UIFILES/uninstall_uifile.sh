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
                        "desc": "Delete all user data in the \"airconnect\" shared folder (linked config/log, if you enabled that during install) - off by default",
                        "defaultValue": false
                    }
                ]
            },
            {
                "desc": "Leave this unchecked to keep the shared folder and its contents, in case you want to reinstall later or keep the logs. This cannot be undone once checked."
            }
        ]
    }
];
EOF

exit 0
