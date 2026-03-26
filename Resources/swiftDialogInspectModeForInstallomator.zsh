#!/bin/zsh --no-rcs
# shellcheck shell=bash

####################################################################################################
#
# swiftDialog Inspect Mode for Installomator
#
# - Installs Installomator Labels specified by:
#   `createInspectConfig` function > dialogInspectModeJSONFile > items:id
# - Monitors installation progress via swiftDialog 3.0.0 Inspect Mode
#
# https://snelson.us/2026/02/swiftdialog-inspect-mode-for-installomator-1-0-0a1/
#
####################################################################################################
#
# HISTORY
#
# Version 1.0.0a1, 23-Feb-2026, Dan K. Snelson (@dan-snelson)
#   - First official alpha release
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/

# Script Version
scriptVersion="1.0.0a1"

# Client-side Log
scriptLog="/var/log/org.churchofjesuschrist.log"

# Installomator Log
installomatorLog="/var/log/Installomator.log"

# Elapsed Time
SECONDS="0"

# Minimum Required Version of swiftDialog
swiftDialogMinimumRequiredVersion="3.0.0.4952"

# Load is-at-least for version comparison
autoload -Uz is-at-least



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Organization Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Organization's swiftDialog Inspect Mode Preset Option (See: https://swiftdialog.app/advanced/inspect-mode/)
organizationPreset="1"

# Script Human-readable Name
humanReadableScriptName="swiftDialog Inspect Mode for Installomator"

# Organization's Script Name
organizationScriptName="sDIMfI"

# Organization's Installomator Path
organizationInstallomatorFile="/Library/Management/AppAutoPatch/Installomator/Installomator.sh"

# Organization's Overlayicon URL
organizationOverlayiconURL="https://swiftdialog.app/_astro/dialog_logo.CZF0LABZ_ZjWz8w.webp"

# Application Icon (Parameter 4)
applicationIcon="${4:-"https://usw2.ics.services.jamfcloud.com/icon/hash_8bf6549c22de3db831aafaf9c5c02d3aa9a928f4abe377eb2f8cbeab3959615c"}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logged-in User Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )
loggedInUserFullname=$( /usr/bin/id -F "${loggedInUser}" )
loggedInUserFirstname=$( /bin/echo "$loggedInUserFullname" | /usr/bin/sed -E 's/^.*, // ; s/([^ ]*).*/\1/' | /usr/bin/sed 's/\(.\{25\}\).*/\1…/' | /usr/bin/awk '{print ( $0 == toupper($0) ? toupper(substr($0,1,1))substr(tolower($0),2) : toupper(substr($0,1,1))substr($0,2) )}' )
loggedInUserID=$( /usr/bin/id -u "${loggedInUser}" )



####################################################################################################
#
# swiftDialog Variables and Functions
#
####################################################################################################

# Title
title="Microsoft 365 Applications"

# swiftDialog Binary Path
dialogBinary="/usr/local/bin/dialog"

# swiftDialog App Bundle
dialogAppBundle="/Library/Application Support/Dialog/Dialog.app"

# swiftDialog Inspect Mode JSON File
dialogInspectModeJSONFile=$( /usr/bin/mktemp -u /var/tmp/dialogJSONFile_InspectMode_${organizationScriptName}.XXXX )

# Create swiftDialog Inspect Mode configuration (thanks, @headmin!)
function createInspectConfig() {
    if ! /bin/cat > "${dialogInspectModeJSONFile}" <<EOF
{
    "preset": "preset${organizationPreset}",
    "title": "{title} Happy $( /bin/date +'%A' ), ${loggedInUserFirstname}! This is Inspect Mode Preset ${organizationPreset}.\n\nInstalling ${title} …",
    "message": "{message} Installing ${title} …",
    "icon": "${applicationIcon}",
    "overlayicon": "${organizationOverlayiconURL}",
    "iconsize": 120,
    "size": "standard",
    "logMonitor": {
        "path": "${installomatorLog}",
        "preset": "installomator",
        "autoMatch": true,
        "startFromEnd": true
    },
    "sideMessage": [
        "{sideMessage} goes here.",
        "Thank you for your patience.",
        "{sideMessage} goes here.",
        "The installation progress is automatically monitored.",
        "{sideMessage} goes here.",
        "Please wait while ${title} is being installed.",
        "{sideMessage} goes here.",
        "Microsoft Word is on its way — create polished documents with ease.",
        "{sideMessage} goes here.",
        "Whether it's a quick memo or a detailed report, Word makes every word count.",
        "{sideMessage} goes here.",
        "Microsoft Excel is installing — turn raw data into powerful decisions.",
        "{sideMessage} goes here.",
        "Crunch numbers with confidence using Excel's formulas, charts, and pivot tables.",
        "{sideMessage} goes here.",
        "Microsoft PowerPoint is coming — make every presentation unforgettable.",
        "{sideMessage} goes here.",
        "Tell your story visually with stunning, professional-quality slides.",
        "{sideMessage} goes here.",
        "Microsoft Outlook is installing — your email, calendar, and contacts, all in one place.",
        "{sideMessage} goes here.",
        "Stay on top of your day with Outlook's intelligent inbox and scheduling tools.",
        "{sideMessage} goes here.",
        "Microsoft OneNote is on its way — capture ideas wherever inspiration strikes.",
        "{sideMessage} goes here.",
        "From meeting notes to project plans, OneNote keeps everything organized and searchable.",
        "{sideMessage} goes here.",
        "OneDrive is installing — access your files from any device, anywhere.",
        "{sideMessage} goes here.",
        "Collaborate in real time and never worry about losing a file again with OneDrive.",
        "{sideMessage} goes here.",
        "Microsoft Teams is on its way — collaborate, meet, and chat all in one app.",
        "{sideMessage} goes here.",
        "Bring your team together instantly with Teams' chat, video, and file-sharing tools."
    ],
    "sideInterval": 8,
    "highlightColor": "#FF904C",
    "button1text": "{button1text} Please wait...",
    "button1disabled": true,
    "autoEnableButton": true,
    "autoEnableButtonText": "{autoEnableButtonText} Close",
    "items": [
        {
            "id": "microsoftword",
            "displayName": "Microsoft Word",
            "paths": ["/Applications/Microsoft Word.app"],
            "icon": "https://usw2.ics.services.jamfcloud.com/icon/hash_51ae4c1e37bfbde2097e14712c3c13885157d632105804bcfaa912a627649b4c"
        },
        {
            "id": "microsoftexcel",
            "displayName": "Microsoft Excel",
            "paths": ["/Applications/Microsoft Excel.app"],
            "icon": "https://usw2.ics.services.jamfcloud.com/icon/hash_9df1c82089b6a3ef006dc6a94995782e1809d6f9767c189a1608067a9f651ca9"
        },
        {
            "id": "microsoftpowerpoint",
            "displayName": "Microsoft PowerPoint",
            "paths": ["/Applications/Microsoft PowerPoint.app"],
            "icon": "https://usw2.ics.services.jamfcloud.com/icon/hash_caadba785f099cec2bb510388390f5239c735a30723ba81b8a0e51792c4adff3"
        },
        {
            "id": "microsoftoutlook",
            "displayName": "Microsoft Outlook",
            "paths": ["/Applications/Microsoft Outlook.app"],
            "icon": "https://usw2.ics.services.jamfcloud.com/icon/hash_e5b0c5b42d26e39431ecc7445ff0122e7d1a73d3487f55ca91b99523136b825d"
        },
        {
            "id": "microsoftonenote",
            "displayName": "Microsoft OneNote",
            "paths": ["/Applications/Microsoft OneNote.app"],
            "icon": "https://usw2.ics.services.jamfcloud.com/icon/hash_e17f32e5366c1d5a3f29f67f8b38470144ecaf597435d2d46523fc1757382ec7"
        },
        {
            "id": "microsoftonedrive",
            "displayName": "OneDrive",
            "paths": ["/Applications/OneDrive.app"],
            "icon": "https://usw2.ics.services.jamfcloud.com/icon/hash_72e08cf3b2dc4d168dc62faf4fc6821b0e0ec79f3382b1567a02b35176024adc"
        },
        {
            "id": "microsoftteamsnew",
            "displayName": "Microsoft Teams",
            "paths": ["/Applications/Microsoft Teams.app"],
            "icon": "https://usw2.ics.services.jamfcloud.com/icon/hash_60344669638073113f3ca25e0a60e7080b5141536dbb62d8920d6e21fa70f877"
        }
    ]
}
EOF
    then
        fatal "Failed to create Dialog inspect config file"
    else
        info "Dialog inspect config file created at ${dialogInspectModeJSONFile}"
    fi
    
    local jqValidationError
    jqValidationError=$(/usr/bin/jq empty "${dialogInspectModeJSONFile}" 2>&1)
    if [[ $? -ne 0 ]]; then
        fatal "Dialog inspect config JSON is malformed: ${jqValidationError}"
    else
        info "Dialog inspect config JSON validated successfully"
    fi

    return 0
}



####################################################################################################
#
# Script Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo "${organizationScriptName} ($scriptVersion): $( /bin/date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | /usr/bin/tee -a "${scriptLog}"
}

function preFlight()    { updateScriptLog "[PRE-FLIGHT]      ${1}"; }
function logComment()   { updateScriptLog "                  ${1}"; }
function notice()       { updateScriptLog "[NOTICE]          ${1}"; }
function info()         { updateScriptLog "[INFO]            ${1}"; }
function error()        { updateScriptLog "[ERROR]           ${1}"; let errorCount++; }
function warning()      { updateScriptLog "[WARNING]         ${1}"; let errorCount++; }
function fatal()        { updateScriptLog "[FATAL ERROR]     ${1}"; exit 1; }



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Run command as logged-in user (thanks, @scriptingosx!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function runAsUser() {
    /bin/launchctl asuser "$loggedInUserID" /usr/bin/sudo -u "$loggedInUser" "$@"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate / install swiftDialog (Thanks big bunches, @acodega!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogInstall() {
    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$(curl -L --silent --fail --connect-timeout 10 --max-time 30 \
        "https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest" \
        | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

    # Validate URL was retrieved
    if [[ -z "${dialogURL}" ]]; then
        fatal "Failed to retrieve swiftDialog download URL from GitHub API"
    fi

    # Validate URL format
    if [[ ! "${dialogURL}" =~ ^https://github\.com/ ]]; then
        fatal "Invalid swiftDialog URL format: ${dialogURL}"
    fi

    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"

    preFlight "Installing swiftDialog from ${dialogURL}..."

    # Create temporary working directory
    workDirectory=$( basename "$0" )
    tempDirectory=$( mktemp -d "/private/tmp/$workDirectory.XXXXXX" )

    # Download the installer package with timeouts
    if ! curl --location --silent --fail --connect-timeout 10 --max-time 60 \
             "$dialogURL" -o "$tempDirectory/Dialog.pkg"; then
        rm -Rf "$tempDirectory"
        fatal "Failed to download swiftDialog package"
    fi

    # Verify the download
    teamID=$(spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')

    # Install the package if Team ID validates
    if [[ "$expectedDialogTeamID" == "$teamID" ]]; then

        installer -pkg "$tempDirectory/Dialog.pkg" -target /
        sleep 2
        dialogVersion=$( /usr/local/bin/dialog --version )
        preFlight "swiftDialog version ${dialogVersion} installed; proceeding..."

    else

        # Display a so-called "simple" dialog if Team ID fails to validate
        osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Dialog Team ID verification failed\r\r" with title "'"${humanReadableScriptName}"' Error" buttons {"Close"} with icon caution'
        exit "1"

    fi

    # Remove the temporary working directory when done
    rm -Rf "$tempDirectory"

}

function dialogCheck() {

    # Check for Dialog and install if not found
    if [[ ! -d "${dialogAppBundle}" ]]; then

        preFlight "swiftDialog not found; installing …"
        dialogInstall
        if [[ ! -x "${dialogBinary}" ]]; then
            fatal "swiftDialog still not found; are downloads from GitHub blocked on this Mac?"
        fi

    else

        dialogVersion=$("${dialogBinary}" --version)
        if ! is-at-least "${swiftDialogMinimumRequiredVersion}" "${dialogVersion}"; then

            preFlight "swiftDialog version ${dialogVersion} found but swiftDialog ${swiftDialogMinimumRequiredVersion} or newer is required; updating …"
            dialogInstall
            if [[ ! -x "${dialogBinary}" ]]; then
                fatal "Unable to update swiftDialog; are downloads from GitHub blocked on this Mac?"
            fi

        else

            preFlight "swiftDialog version ${dialogVersion} found; proceeding …"

        fi

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Installomator Install via Inspect Mode
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

installomatorInstallInspectItem() {
    local installomatorLabel installomatorExitCode dialogPID

    # Create Dialog configuration
    notice "Create Dialog …"
    if ! createInspectConfig; then
        fatal "Failed to create Dialog inspect config"
    else
        info "Dialog inspect config created at ${dialogInspectModeJSONFile}"
    fi

    # Launch Dialog in background for real-time progress
    runAsUser DIALOG_INSPECT_CONFIG="${dialogInspectModeJSONFile}" "${dialogBinary}" --inspect-mode &
    dialogPID=$!
    info "Inspect Mode PID: ${dialogPID}"

    # Install each label; Dialog reads Installomator.log directly via logMonitor
    # Label IDs and app paths are derived from the JSON config (items[].id and items[].paths[0])
    while IFS=$'\t' read -r installomatorLabel appPath; do
        if [[ -n "${appPath}" && -d "${appPath}" ]]; then
            info "Skipping '${installomatorLabel}': ${appPath} already exists"
            continue
        fi
        notice "Installing '${installomatorLabel}' …"
        "${organizationInstallomatorFile}" "${installomatorLabel}" \
            DEBUG=0 NOTIFY=silent 2>&1 | while IFS= read -r installomatorOutputLine; do
                logComment "Installomator (${installomatorLabel}): ${installomatorOutputLine}"
            done
        installomatorExitCode=${pipestatus[1]}

        if [[ ${installomatorExitCode} -ne 0 ]]; then
            error "Installomator failed for '${installomatorLabel}' (exit code: ${installomatorExitCode})"
        else
            info "Installomator completed for '${installomatorLabel}'"
        fi
    done < <(/usr/bin/jq -r '.items[] | [.id, .paths[0]] | @tsv' "${dialogInspectModeJSONFile}")

    # Wait for Dialog to close
    info "Waiting for Inspect Mode (PID: ${dialogPID}) to close …"
    wait "${dialogPID}"
    info "Inspect Mode closed."
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit Script (thanks, @bartreadon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function quitScript() {
    exitCode="${1:-0}"
    
    notice "Exiting …"
    
    # Kill dialog process if still running
    if [[ -n "${dialogPID}" ]]; then
        if kill -0 "${dialogPID}" 2>/dev/null; then
            info "Terminating Inspect Mode (PID: ${dialogPID})"
            kill "${dialogPID}" 2>/dev/null || true
            /bin/sleep 1
        fi
    fi
    
    # Remove the dialog-related JSON files
    /bin/rm -f /var/tmp/dialogJSONFile_*

    # Remove default dialog.log
    /bin/rm -f /var/tmp/dialog.log
    
    info "Total Elapsed Time: $(/usr/bin/printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60)))"
    info "So long!"
    
    exit "${exitCode}"
}



####################################################################################################
#
# Pre-flight Checks
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    /usr/bin/touch "${scriptLog}"
    if [[ -f "${scriptLog}" ]]; then
        preFlight "Created specified scriptLog: ${scriptLog}"
        preFlight "Continuing pre-flight checks …"
    else
        fatal "Unable to create specified scriptLog '${scriptLog}'; exiting.\n\n(Is this script running as 'root' ?)"
    fi
fi

# Check and rotate log if exceeds max size
logSize=$(/usr/bin/stat -f%z "${scriptLog}" 2>/dev/null || /bin/echo "0")
maxLogSize=$((10 * 1024 * 1024))  # 10MB

if (( logSize > maxLogSize )); then
    preFlight "Log file exceeds ${maxLogSize} bytes; rotating"
    if /bin/mv "${scriptLog}" "${scriptLog}.$(/bin/date +%s).old" 2>/dev/null; then
        /usr/bin/touch "${scriptLog}"
        preFlight "Log file rotated"
    else
        warning "Unable to rotate log file"
    fi
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

preFlight "\n\n###\n# $humanReadableScriptName (${scriptVersion})\n# https://snelson.us/2026/02/swiftdialog-inspect-mode-for-installomator-1-0-0a1/\n####\n\n"
preFlight "Pre-flight Check: Initiating …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    fatal "ERROR: This script must be run as root; exiting."
else
    preFlight "Pre-flight Check: Running as root; proceeding …"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm Installomator is available
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -x "${organizationInstallomatorFile}" ]]; then
    fatal "Installomator not found at ${organizationInstallomatorFile}; exiting."
else
    preFlight "Installomator found at ${organizationInstallomatorFile}; proceeding …"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate / install swiftDialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogCheck



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Complete
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

preFlight "Complete!"



####################################################################################################
#
# Program
#
####################################################################################################


installomatorInstallInspectItem
quitScript 0
