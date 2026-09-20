#!/bin/sh

# Work out what this install is doing right now, so the wizard opens with
# the current setting instead of a default. Getting this wrong is not
# cosmetic: an unchecked box makes postupgrade write
# AIRCONNECT_SHARED_FOLDER_LINKS_ENABLED=0 and remove the links, taking
# away access the install was relying on.
#
# Three sources, in order of certainty:
#   1. the setting in the config of the installed version,
#   2. the shared folder itself - a config written before the setting
#      existed has no line to read, and those installs always had the
#      links, so an absent line must never be read as "off",
#   3. nothing: then the checkbox is left out of the wizard entirely and
#      postupgrade keeps whatever is configured.
CONFIG_FILE="airconnect.conf"
CONFIG_KEY="AIRCONNECT_SHARED_FOLDER_LINKS_ENABLED"
SHARE_NAME="airconnect"
LOG_FILE="airconnect.log"

CURRENT_VALUE=""
for conf in "${SYNOPKG_PKGDEST}/${CONFIG_FILE}" /var/packages/*/target/"${CONFIG_FILE}"; do
    [ -r "${conf}" ] || continue
    case "$(sed -n "s/^${CONFIG_KEY}=\\(.*\\)/\\1/p" "${conf}" | tail -n 1)" in
    1) CURRENT_VALUE="true" ;;
    "") ;; # predates the setting - decided by the shared folder below
    *) CURRENT_VALUE="false" ;;
    esac
    break
done

if [ -z "${CURRENT_VALUE}" ]; then
    for marker in \
        "${SYNOPKG_PKGDEST_VOL}/${SHARE_NAME}/${CONFIG_FILE}" \
        "${SYNOPKG_PKGDEST_VOL}/${SHARE_NAME}/log/${LOG_FILE}" \
        /volume*/"${SHARE_NAME}"/"${CONFIG_FILE}" \
        /volume*/"${SHARE_NAME}"/config.xml \
        /volume*/"${SHARE_NAME}"/config-cast.xml \
        /volume*/"${SHARE_NAME}"/log/"${LOG_FILE}"; do
        if [ -e "${marker}" ] || [ -L "${marker}" ]; then
            CURRENT_VALUE="true"
            break
        fi
    done
fi

# The toggle is only offered when the current setting is known. When it is
# not, the step explains that and carries no checkbox at all, so nothing
# is submitted for it and postupgrade keeps the existing setting.
if [ -n "${CURRENT_VALUE}" ]; then
    ITEMS="{
                \"type\": \"multiselect\",
                \"desc\": \"Link config.xml/config-cast.xml, airconnect.conf and the log into a shared folder reachable over a network share (SMB) - lets you place a custom config.xml, edit airconnect.conf, or check the log from your computer without SSH. The box below shows what this installation uses today; leave it as it is to keep that.\",
                \"subitems\": [
                    {
                        \"key\": \"pkgwizard_create_shared_folder\",
                        \"desc\": \"Enable shared-folder links\",
                        \"defaultValue\": ${CURRENT_VALUE}
                    }
                ]
            },
            {
                \"desc\": \"<strong style='color:red'>Note:</strong> works over SMB only - map the shared folder from Windows, Mac, or Linux (e.g. smb://&lt;your-nas&gt;/airconnect). Not supported via File Station (can't display symlinks) or AFP (no equivalent setting). You also need to enable 'allow symlinks' under <em>Control Panel - File Services - SMB - Advanced Settings</em> on your Synology device - a device-wide setting, not specific to this package. See the <a target='_blank' href='https://github.com/eizedev/AirConnect-Synology#readme'>documentation</a> for details and a screenshot.\"
            }"
else
    ITEMS="{
                \"desc\": \"This installation's shared-folder setting could not be read, so it is kept exactly as it is and cannot be changed here. To change it, set AIRCONNECT_SHARED_FOLDER_LINKS_ENABLED in airconnect.conf over SSH and restart the package, or reinstall it.\"
            }"
fi

tee "$SYNOPKG_TEMP_LOGFILE" <<EOF
[
    {
        "step_title": "Optional: Shared folder for GUI access",
        "items": [
            ${ITEMS}
        ]
    }
];
EOF

exit 0
