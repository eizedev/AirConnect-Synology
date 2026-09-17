#!/bin/sh

# Preselect the current setting (read from the not-yet-upgraded config at
# SYNOPKG_PKGDEST, which still holds the currently-installed version's
# files at this point in the lifecycle) rather than always defaulting to
# off, so upgrading doesn't silently reset a choice already made.
CURRENT_VALUE="false"
if grep -q '^AIRCONNECT_SHARED_FOLDER_LINKS_ENABLED=1' "${SYNOPKG_PKGDEST}/airconnect.conf" 2>/dev/null; then
    CURRENT_VALUE="true"
fi

tee "$SYNOPKG_TEMP_LOGFILE" <<EOF
[
    {
        "step_title": "Optional: Shared folder for GUI access",
        "items": [
            {
                "type": "multiselect",
                "desc": "Link config.xml/config-cast.xml, airconnect.conf and the log into a shared folder reachable over a network share (SMB) - lets you place a custom config.xml, edit airconnect.conf, or check the log from your computer without SSH. Most installs never need this - the defaults are already tuned to just work. Need something else made configurable here instead? Open an issue.",
                "subitems": [
                    {
                        "key": "pkgwizard_create_shared_folder",
                        "desc": "Enable shared-folder links (off by default)",
                        "defaultValue": $CURRENT_VALUE
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
