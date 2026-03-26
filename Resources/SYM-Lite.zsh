#!/bin/zsh --no-rcs
# shellcheck shell=bash

####################################################################################################
#
# SYM-Lite
#
# - Lean, purpose-built script for executing Jamf Pro Policy Custom Triggers and Installomator labels
# - User selects which items to install/execute via swiftDialog selection UI
# - Monitors execution progress via swiftDialog 3.0.0 Inspect Mode
# - No user input prompts beyond selection (no asset tag, computer name, etc.)
#
# https://snelson.us/sym
#
####################################################################################################
#
# HISTORY
#
# Version 0.0.1a1, 26-Mar-2026, Dan K. Snelson (@dan-snelson)
#   - Initial alpha release
#   - Unified Installomator label and Jamf Pro policy execution
#   - swiftDialog Inspect Mode with dual log monitoring
#   - Selection-based workflow with no additional user input
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
setopt NONOMATCH

# Script Version
scriptVersion="0.0.1a1"

# Script Human-readable Name
humanReadableScriptName="SYM-Lite"

# Organization's Script Name
organizationScriptName="SYML"

# Client-side Log
scriptLog="/var/log/org.churchofjesuschrist.log"

# Installomator Log
installomatorLog="/var/log/Installomator.log"

# Jamf Log
jamfLog="/var/log/jamf.log"

# Elapsed Time
SECONDS="0"

# Minimum Required Version of swiftDialog
swiftDialogMinimumRequiredVersion="3.0.0.4952"

# Load is-at-least for version comparison
autoload -Uz is-at-least



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Runtime Parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Runtime inputs (Jamf parameters by default; CLI flags can override)
operationMode="${4:-"interactive"}"     # Parameter 4: Operation Mode [ interactive (default) | silent ]
operationsCSV="${5:-""}"                # Parameter 5: Comma-separated list of item IDs for silent mode



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Organization Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Organization's swiftDialog Inspect Mode Preset Option (See: https://swiftdialog.app/advanced/inspect-mode/)
organizationPreset="1"

# Organization's Installomator Path
organizationInstallomatorFile="/Library/Management/AppAutoPatch/Installomator/Installomator.sh"

# Organization's Jamf Binary Path
jamfBinary="/usr/local/bin/jamf"

# Organization's Overlayicon URL
organizationOverlayiconURL="https://swiftdialog.app/_astro/dialog_logo.CZF0LABZ_ZjWz8w.webp"

# Main Dialog Icon
mainDialogIcon="SF=gearshape.2,weight=semibold,colour1=#51a3ef,colour2=#5154ef"

# Dialog presentation defaults
fontSize="14"

# Restart prompt behavior
restartPromptEnabled="true"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Item Configuration Arrays
# Format: "identifier:displayName:validationPath:iconURL"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Installomator Items
# Format: "label:Display Name:Validation Path:Icon URL"
installomatorItems=(
    "microsoftword:Microsoft Word:/Applications/Microsoft Word.app:https://usw2.ics.services.jamfcloud.com/icon/hash_51ae4c1e37bfbde2097e14712c3c13885157d632105804bcfaa912a627649b4c"
    "microsoftexcel:Microsoft Excel:/Applications/Microsoft Excel.app:https://usw2.ics.services.jamfcloud.com/icon/hash_9df1c82089b6a3ef006dc6a94995782e1809d6f9767c189a1608067a9f651ca9"
    "microsoftpowerpoint:Microsoft PowerPoint:/Applications/Microsoft PowerPoint.app:https://usw2.ics.services.jamfcloud.com/icon/hash_caadba785f099cec2bb510388390f5239c735a30723ba81b8a0e51792c4adff3"
    "googlechrome:Google Chrome:/Applications/Google Chrome.app:https://usw2.ics.services.jamfcloud.com/icon/hash_6226b1b2b4734e04fc2b96c035ecc115a8ba4c54e45bdee5b28b25c35a66e223"
    "firefox:Mozilla Firefox:/Applications/Firefox.app:https://usw2.ics.services.jamfcloud.com/icon/hash_e4929928e40e95a57f5cf3e1e4295d57aea40f6b6a7c1f5c2e4e6d0e02c75d3d"
    "zoom:Zoom:/Applications/zoom.us.app:https://usw2.ics.services.jamfcloud.com/icon/hash_4d61a4c0ea2bd9a5f69d8c5e5f5c5f4f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f"
    "adobeacrobatreader:Adobe Acrobat Reader:/Applications/Adobe Acrobat Reader.app:https://usw2.ics.services.jamfcloud.com/icon/hash_8d7b10f0e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5"
    "vlc:VLC Media Player:/Applications/VLC.app:https://usw2.ics.services.jamfcloud.com/icon/hash_3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f"
)

# Jamf Pro Policy Items
# Format: "trigger:Display Name:Validation Path:Icon URL"
jamfPolicyItems=(
    "installRosetta:Install Rosetta 2:/usr/bin/arch:SF=cpu,weight=semibold,colour1=auto,colour2=auto"
    "enableFileVault:Enable FileVault Encryption:/Library/Preferences/com.apple.fdesetup.plist:SF=lock.shield.fill,weight=semibold,colour1=auto,colour2=auto"
    "installCompanyVPN:Install Company VPN:/Applications/Company VPN.app:SF=network.badge.shield.half.filled,weight=semibold,colour1=auto,colour2=auto"
    "configureDock:Configure Dock:/usr/local/bin/dockutil:SF=dock.rectangle,weight=semibold,colour1=auto,colour2=auto"
)



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logged-in User Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )
loggedInUserFullname=$( /usr/bin/id -F "${loggedInUser}" )
loggedInUserFirstname=$( /bin/echo "$loggedInUserFullname" | /usr/bin/sed -E 's/^.*, // ; s/([^ ]*).*/\1/' | /usr/bin/sed 's/\(.\{25\}\).*/\1…/' | /usr/bin/awk '{print ( $0 == toupper($0) ? toupper(substr($0,1,1))substr(tolower($0),2) : toupper(substr($0,1,1))substr($0,2) )}' )
loggedInUserID=$( /usr/bin/id -u "${loggedInUser}" )



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# swiftDialog Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# swiftDialog Binary Path
dialogBinary="/usr/local/bin/dialog"

# swiftDialog App Bundle
dialogAppBundle="/Library/Application Support/Dialog/Dialog.app"

# swiftDialog Inspect Mode JSON File
dialogInspectModeJSONFile=$( /usr/bin/mktemp -u /var/tmp/dialogJSONFile_InspectMode_${organizationScriptName}.XXXX )



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Runtime Tracking Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

selectedItems=()
selectedInstallomatorLabels=()
selectedJamfPolicies=()
failedItems=()
completedItems=()
skippedItems=()
dialogPID=""
workDirectory=""



####################################################################################################
#
# Logging Helpers
#
####################################################################################################

function updateScriptLog() {
    local level="$1"
    local message="$2"
    echo "${organizationScriptName} (${scriptVersion}): $(date '+%Y-%m-%d %H:%M:%S')  [${level}] ${message}" | tee -a "${scriptLog}" >&2
}

function preFlight()    { updateScriptLog "PRE-FLIGHT" "${1}"; }
function logComment()   { updateScriptLog "INFO" "${1}"; }
function notice()       { updateScriptLog "NOTICE" "${1}"; }
function info()         { updateScriptLog "INFO" "${1}"; }
function warning()      { updateScriptLog "WARNING" "${1}"; }
function errorOut()     { updateScriptLog "ERROR" "${1}"; }
function fatal()        { updateScriptLog "FATAL ERROR" "${1}"; exit 10; }

function cleanup() {
    rm -f "${dialogInspectModeJSONFile}" 2>/dev/null
    rm -rf "${workDirectory}" 2>/dev/null
    rm -f /var/tmp/dialogJSONFile_* 2>/dev/null
    rm -f /var/tmp/dialog.log 2>/dev/null
}
trap cleanup EXIT



####################################################################################################
#
# Core Helper Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Run command as logged-in user (thanks, @scriptingosx!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function runAsUser() {
    /bin/launchctl asuser "$loggedInUserID" /usr/bin/sudo -u "$loggedInUser" "$@"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse Installomator Item Configuration
# Input: "label:displayName:validationPath:iconURL"
# Output: Sets global variables itemLabel, itemDisplayName, itemValidationPath, itemIconURL
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function parseInstallomatorItem() {
    local itemConfig="$1"
    local oldIFS="$IFS"
    IFS=':'
    local parts=("${(@s/:/)itemConfig}")
    IFS="$oldIFS"
    
    itemLabel="${parts[1]}"
    itemDisplayName="${parts[2]}"
    itemValidationPath="${parts[3]}"
    itemIconURL="${parts[4]}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse Jamf Policy Item Configuration
# Input: "trigger:displayName:validationPath:iconURL"
# Output: Sets global variables itemTrigger, itemDisplayName, itemValidationPath, itemIconURL
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function parseJamfPolicyItem() {
    local itemConfig="$1"
    local oldIFS="$IFS"
    IFS=':'
    local parts=("${(@s/:/)itemConfig}")
    IFS="$oldIFS"
    
    itemTrigger="${parts[1]}"
    itemDisplayName="${parts[2]}"
    itemValidationPath="${parts[3]}"
    itemIconURL="${parts[4]}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Get All Item IDs
# Returns: Array of all item identifiers (labels + triggers)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function getAllItemIDs() {
    local allIDs=()
    
    # Add Installomator labels
    for item in "${installomatorItems[@]}"; do
        local oldIFS="$IFS"
        IFS=':'
        local parts=("${(@s/:/)item}")
        IFS="$oldIFS"
        allIDs+=("${parts[1]}")
    done
    
    # Add Jamf policy triggers
    for item in "${jamfPolicyItems[@]}"; do
        local oldIFS="$IFS"
        IFS=':'
        local parts=("${(@s/:/)item}")
        IFS="$oldIFS"
        allIDs+=("${parts[1]}")
    done
    
    echo "${allIDs[@]}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Get Item Type
# Input: Item ID
# Output: "installomator" or "jamf" or empty string if not found
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function getItemType() {
    local itemID="$1"
    
    # Check Installomator items
    for item in "${installomatorItems[@]}"; do
        local oldIFS="$IFS"
        IFS=':'
        local parts=("${(@s/:/)item}")
        IFS="$oldIFS"
        if [[ "${parts[1]}" == "${itemID}" ]]; then
            echo "installomator"
            return 0
        fi
    done
    
    # Check Jamf policy items
    for item in "${jamfPolicyItems[@]}"; do
        local oldIFS="$IFS"
        IFS=':'
        local parts=("${(@s/:/)item}")
        IFS="$oldIFS"
        if [[ "${parts[1]}" == "${itemID}" ]]; then
            echo "jamf"
            return 0
        fi
    done
    
    echo ""
    return 1
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Get Item Configuration
# Input: Item ID
# Output: Full configuration string
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function getItemConfig() {
    local itemID="$1"
    
    # Check Installomator items
    for item in "${installomatorItems[@]}"; do
        local oldIFS="$IFS"
        IFS=':'
        local parts=("${(@s/:/)item}")
        IFS="$oldIFS"
        if [[ "${parts[1]}" == "${itemID}" ]]; then
            echo "${item}"
            return 0
        fi
    done
    
    # Check Jamf policy items
    for item in "${jamfPolicyItems[@]}"; do
        local oldIFS="$IFS"
        IFS=':'
        local parts=("${(@s/:/)item}")
        IFS="$oldIFS"
        if [[ "${parts[1]}" == "${itemID}" ]]; then
            echo "${item}"
            return 0
        fi
    done
    
    echo ""
    return 1
}



####################################################################################################
#
# swiftDialog Functions
#
####################################################################################################

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
# Formatted Elapsed Time
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function formattedElapsedTime() {
    /usr/bin/printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60))
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
    
    cleanup
    
    info "Total Elapsed Time: $(formattedElapsedTime)"
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

preFlight "\n\n###\n# $humanReadableScriptName (${scriptVersion})\n# https://snelson.us/sym\n###\n"
preFlight "Initiating …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    fatal "This script must be run as root; exiting."
fi

preFlight "Running as root; proceeding …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate swiftDialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogCheck



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Installomator (if Installomator items configured)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ${#installomatorItems[@]} -gt 0 ]]; then
    if [[ ! -x "${organizationInstallomatorFile}" ]]; then
        warning "Installomator not found at ${organizationInstallomatorFile}"
        warning "Installomator items will be skipped"
    else
        preFlight "Installomator found at ${organizationInstallomatorFile}"
    fi
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Jamf Binary (if Jamf policy items configured)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ${#jamfPolicyItems[@]} -gt 0 ]]; then
    if [[ ! -x "${jamfBinary}" ]]; then
        warning "Jamf binary not found at ${jamfBinary}"
        warning "Jamf policy items will be skipped"
    else
        preFlight "Jamf binary found at ${jamfBinary}"
    fi
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Complete
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

preFlight "Pre-flight checks complete!"



####################################################################################################
#
# Inspect Mode Configuration Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create swiftDialog Inspect Mode Configuration
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function createSYMLiteInspectConfig() {
    local totalItems=${#selectedItems[@]}
    local dialogTitle="Installing ${totalItems} Application"
    [[ ${totalItems} -gt 1 ]] && dialogTitle="${dialogTitle}s"
    dialogTitle="${dialogTitle} and Policies"
    
    # Build items array JSON
    local itemsJSON=""
    local firstItem=true
    
    for itemID in "${selectedItems[@]}"; do
        local itemType
        itemType=$(getItemType "${itemID}")
        
        local itemConfig
        itemConfig=$(getItemConfig "${itemID}")
        
        if [[ "${itemType}" == "installomator" ]]; then
            parseInstallomatorItem "${itemConfig}"
            local jsonBlock="{
            \"id\": \"${itemLabel}\",
            \"displayName\": \"${itemDisplayName}\",
            \"paths\": [\"${itemValidationPath}\"],
            \"icon\": \"${itemIconURL}\"
        }"
        elif [[ "${itemType}" == "jamf" ]]; then
            parseJamfPolicyItem "${itemConfig}"
            local jsonBlock="{
            \"id\": \"${itemTrigger}\",
            \"displayName\": \"${itemDisplayName}\",
            \"paths\": [\"${itemValidationPath}\"],
            \"icon\": \"${itemIconURL}\"
        }"
        else
            warning "Unknown item type for ID: ${itemID}"
            continue
        fi
        
        if [[ "${firstItem}" == "true" ]]; then
            itemsJSON="${jsonBlock}"
            firstItem=false
        else
            itemsJSON="${itemsJSON},
        ${jsonBlock}"
        fi
    done
    
    # Create the full JSON configuration
    if ! /bin/cat > "${dialogInspectModeJSONFile}" <<EOF
{
    "preset": "preset${organizationPreset}",
    "title": "${dialogTitle}",
    "message": "Installing selected applications and executing policies. Progress is monitored automatically.",
    "icon": "${mainDialogIcon}",
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
        "Thank you for your patience.",
        "Installation progress is automatically monitored.",
        "Applications are being installed via Installomator.",
        "Policies are being executed via Jamf Pro.",
        "Please wait while items are being processed.",
        "Each item is verified after installation.",
        "This process may take several minutes.",
        "You can minimize this window if needed.",
        "The installation will complete automatically.",
        "A restart may be required after completion."
    ],
    "sideInterval": 8,
    "highlightColor": "#51a3ef",
    "button1text": "Please wait...",
    "button1disabled": true,
    "autoEnableButton": true,
    "autoEnableButtonText": "Close",
    "items": [
        ${itemsJSON}
    ]
}
EOF
    then
        fatal "Failed to create Dialog inspect config file"
    else
        info "Dialog inspect config file created at ${dialogInspectModeJSONFile}"
    fi
    
    # Validate JSON with jq
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
# Selection Interface Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse Operations CSV (for silent mode)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function parseOperationsCSV() {
    local csv="$1"
    selectedItems=()
    [[ -z "${csv}" ]] && return 0

    local oldIFS="$IFS"
    IFS=','
    local itemID
    for itemID in ${csv}; do
        itemID="${itemID// /}"                    # Strip whitespace
        [[ -z "${itemID}" ]] && continue          # Skip empty entries
        
        # Validate item exists
        local itemType
        itemType=$(getItemType "${itemID}")
        if [[ -n "${itemType}" ]]; then
            # Add only if not already present
            if [[ ! " ${selectedItems[@]} " =~ " ${itemID} " ]]; then
                selectedItems+=("${itemID}")
            fi
        else
            warning "Unknown item ID in CSV: '${itemID}'"
        fi
    done
    IFS="${oldIFS}"
    
    info "Parsed CSV: ${#selectedItems[@]} valid items selected"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse Dialog Selections (from JSON output)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function parseDialogSelections() {
    local output="$1"
    selectedItems=()

    # Get all possible item IDs
    local allIDs
    allIDs=($(getAllItemIDs))

    # Primary: regex search for pattern like "itemID": true
    local itemID
    for itemID in "${allIDs[@]}"; do
        if echo "${output}" | grep -Eiq "${itemID}\"?[[:space:]]*:[[:space:]]*(true|1|yes)"; then
            selectedItems+=("${itemID}")
        fi
    done

    # Fallback: JSON-aware jq parsing if grep found nothing
    if [[ ${#selectedItems[@]} -eq 0 ]] && command -v jq >/dev/null 2>&1; then
        for itemID in "${allIDs[@]}"; do
            if echo "${output}" | jq -e ".${itemID} == true" >/dev/null 2>&1; then
                selectedItems+=("${itemID}")
            fi
        done
    fi
    
    info "Parsed dialog selections: ${#selectedItems[@]} items selected"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Show Selection Dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function showSelectionDialog() {
    if [[ "${operationMode}" == "silent" ]]; then
        parseOperationsCSV "${operationsCSV}"
        return 0
    fi

    local checkboxArgs=()
    local baseMessage
    local warningMessage=""
    local messageText
    local dialogOutput
    local rc

    # Build message
    baseMessage="Select one or more applications or policies to install/execute.\n\n**Installomator Labels** and **Jamf Pro Policies** can be selected together."

    # Add Installomator items as checkboxes with header
    if [[ ${#installomatorItems[@]} -gt 0 ]]; then
        checkboxArgs+=(--selecttitle "Installomator Labels")
        for item in "${installomatorItems[@]}"; do
            parseInstallomatorItem "${item}"
            checkboxArgs+=(--checkbox "${itemDisplayName},name=${itemLabel}")
        done
    fi

    # Add Jamf policy items as checkboxes with header
    if [[ ${#jamfPolicyItems[@]} -gt 0 ]]; then
        checkboxArgs+=(--selecttitle "Jamf Pro Policies")
        for item in "${jamfPolicyItems[@]}"; do
            parseJamfPolicyItem "${item}"
            checkboxArgs+=(--checkbox "${itemDisplayName},name=${itemTrigger}")
        done
    fi

    # Loop until at least one item is selected
    while true; do
        messageText="${baseMessage}"
        if [[ -n "${warningMessage}" ]]; then
            messageText="${messageText}\n\n**${warningMessage}**"
        fi

        dialogOutput="$(${dialogBinary} \
            --title "${humanReadableScriptName}" \
            --infotext "Version ${scriptVersion}" \
            --messagefont "size=${fontSize}" \
            --message "${messageText}" \
            --icon "${mainDialogIcon}" \
            --checkboxstyle "switch,small" \
            --json \
            --button1text "Install" \
            --button2text "Cancel" \
            "${checkboxArgs[@]}" 2>/dev/null)"

        rc=$?
        if [[ ${rc} -ne 0 ]]; then
            info "User cancelled selection dialog"
            quitScript 2
        fi

        parseDialogSelections "${dialogOutput}"
        if [[ ${#selectedItems[@]} -gt 0 ]]; then
            notice "User selected ${#selectedItems[@]} items"
            return 0
        fi

        # Warn and retry if no selections
        warning "No items selected in picker; re-showing selection dialog"
        warningMessage=":red[Warning:] Please select at least **one** option before clicking **Install**."
    done
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Separate Selected Items by Type
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function separateSelectedItemsByType() {
    selectedInstallomatorLabels=()
    selectedJamfPolicies=()
    
    for itemID in "${selectedItems[@]}"; do
        local itemType
        itemType=$(getItemType "${itemID}")
        
        if [[ "${itemType}" == "installomator" ]]; then
            selectedInstallomatorLabels+=("${itemID}")
        elif [[ "${itemType}" == "jamf" ]]; then
            selectedJamfPolicies+=("${itemID}")
        fi
    done
    
    info "Separated selections: ${#selectedInstallomatorLabels[@]} Installomator, ${#selectedJamfPolicies[@]} Jamf policies"
}



####################################################################################################
#
# Execution Engine Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Execute Installomator Label
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function executeInstallomatorLabel() {
    local label="$1"
    local validationPath="$2"
    local displayName="$3"
    local installomatorExitCode
    
    # Check if already installed
    if [[ -n "${validationPath}" && -e "${validationPath}" ]]; then
        info "Skipping '${label}': ${validationPath} already exists"
        skippedItems+=("${label}")
        return 0
    fi
    
    notice "Installing '${label}' (${displayName}) …"
    
    # Execute Installomator
    "${organizationInstallomatorFile}" "${label}" \
        DEBUG=0 NOTIFY=silent 2>&1 | while IFS= read -r installomatorOutputLine; do
            logComment "Installomator (${label}): ${installomatorOutputLine}"
        done
    installomatorExitCode=${pipestatus[1]}

    if [[ ${installomatorExitCode} -ne 0 ]]; then
        errorOut "Installomator failed for '${label}' (exit code: ${installomatorExitCode})"
        failedItems+=("${displayName}")
        return 1
    else
        info "Installomator completed for '${label}'"
        completedItems+=("${displayName}")
        return 0
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Execute Jamf Policy
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function executeJamfPolicy() {
    local trigger="$1"
    local validationPath="$2"
    local displayName="$3"
    local jamfExitCode
    
    # Check if already configured (validation path exists)
    if [[ -n "${validationPath}" && -e "${validationPath}" ]]; then
        info "Skipping policy '${trigger}': ${validationPath} already exists"
        skippedItems+=("${trigger}")
        return 0
    fi
    
    notice "Executing Jamf policy '${trigger}' (${displayName}) …"
    
    # Execute Jamf policy and log output to jamf.log for Inspect Mode monitoring
    "${jamfBinary}" policy -event "${trigger}" 2>&1 | while IFS= read -r jamfOutputLine; do
        logComment "Jamf (${trigger}): ${jamfOutputLine}"
        # Also write to jamf.log for potential Inspect Mode secondary monitoring
        echo "$(date '+%Y-%m-%d %H:%M:%S') [${trigger}] ${jamfOutputLine}" >> "${jamfLog}"
    done
    jamfExitCode=${pipestatus[1]}

    # Post-execution validation
    if [[ ${jamfExitCode} -eq 0 ]]; then
        if [[ -n "${validationPath}" && -e "${validationPath}" ]]; then
            info "Jamf policy '${trigger}' completed successfully and validated"
            completedItems+=("${displayName}")
            return 0
        else
            warning "Jamf policy '${trigger}' completed but validation path not found: ${validationPath}"
            # Still mark as completed since jamf returned 0
            completedItems+=("${displayName}")
            return 0
        fi
    else
        errorOut "Jamf policy '${trigger}' failed (exit code: ${jamfExitCode})"
        failedItems+=("${displayName}")
        return 1
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Unified Execution Dispatcher
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function executeSYMLiteItems() {
    notice "Starting execution of ${#selectedItems[@]} selected items"
    
    # Create Inspect Mode configuration
    notice "Creating Inspect Mode configuration …"
    if ! createSYMLiteInspectConfig; then
        fatal "Failed to create Inspect Mode configuration"
    fi
    
    # Launch Dialog in background for real-time progress
    notice "Launching Inspect Mode dialog …"
    runAsUser DIALOG_INSPECT_CONFIG="${dialogInspectModeJSONFile}" "${dialogBinary}" --inspect-mode &
    dialogPID=$!
    info "Inspect Mode PID: ${dialogPID}"
    
    # Give dialog a moment to launch
    sleep 2
    
    # Process each selected item sequentially
    for itemID in "${selectedItems[@]}"; do
        local itemType
        itemType=$(getItemType "${itemID}")
        
        local itemConfig
        itemConfig=$(getItemConfig "${itemID}")
        
        if [[ "${itemType}" == "installomator" ]]; then
            parseInstallomatorItem "${itemConfig}"
            executeInstallomatorLabel "${itemLabel}" "${itemValidationPath}" "${itemDisplayName}"
        elif [[ "${itemType}" == "jamf" ]]; then
            parseJamfPolicyItem "${itemConfig}"
            executeJamfPolicy "${itemTrigger}" "${itemValidationPath}" "${itemDisplayName}"
        else
            warning "Unknown item type for ID: ${itemID}"
        fi
    done
    
    # Wait for Dialog to close
    info "Waiting for Inspect Mode (PID: ${dialogPID}) to close …"
    wait "${dialogPID}"
    info "Inspect Mode closed."
    
    notice "Execution complete: ${#completedItems[@]} completed, ${#skippedItems[@]} skipped, ${#failedItems[@]} failed"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Interruption Handler
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function handleInterruption() {
    warning "Script interrupted by user"
    
    # Kill dialog if still running
    if [[ -n "${dialogPID}" ]]; then
        if kill -0 "${dialogPID}" 2>/dev/null; then
            info "Terminating Inspect Mode (PID: ${dialogPID})"
            kill "${dialogPID}" 2>/dev/null || true
        fi
    fi
    
    cleanup
    exit 130
}

trap handleInterruption SIGINT SIGTERM



####################################################################################################
#
# Completion and Restart Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Completion Dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function showCompletionDialog() {
    local dialogTitle
    local dialogMessage
    local dialogIcon
    local failedItemsList=""
    
    if [[ ${#failedItems[@]} -gt 0 ]]; then
        # Completion with errors
        dialogTitle="Completed with Errors"
        dialogIcon="SF=exclamationmark.triangle.fill,weight=bold,colour1=#FF9500,colour2=#FF5500"
        
        dialogMessage="**${#completedItems[@]}** of **${#selectedItems[@]}** items completed successfully.\n\n"
        dialogMessage="${dialogMessage}The following items failed:\n\n"
        
        for item in "${failedItems[@]}"; do
            failedItemsList="${failedItemsList}• ${item}\n"
        done
        
        dialogMessage="${dialogMessage}${failedItemsList}"
    else
        # All successful
        dialogTitle="Installation Complete"
        dialogIcon="SF=checkmark.circle.fill,weight=bold,colour1=#00C40C,colour2=##00C40C"
        
        if [[ ${#skippedItems[@]} -gt 0 ]]; then
            dialogMessage="**${#completedItems[@]}** items installed successfully.\n\n**${#skippedItems[@]}** items were already installed and skipped."
        else
            dialogMessage="All **${#selectedItems[@]}** selected items installed successfully."
        fi
    fi
    
    ${dialogBinary} \
        --title "${dialogTitle}" \
        --infotext "Version ${scriptVersion}" \
        --messagefont "size=${fontSize}" \
        --message "${dialogMessage}" \
        --icon "${dialogIcon}" \
        --button1text "Close" \
        --width 600 \
        --height 400 2>/dev/null
    
    notice "Completion dialog closed"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Restart Prompt
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptForRestart() {
    if [[ "${restartPromptEnabled}" != "true" ]] || [[ "${operationMode}" == "silent" ]]; then
        return 0
    fi
    
    local rc
    
    ${dialogBinary} \
        --title "Restart Recommended" \
        --infotext "Version ${scriptVersion}" \
        --messagefont "size=${fontSize}" \
        --message "A restart is recommended to complete the installation.\n\nWould you like to restart now?" \
        --icon "SF=arrow.clockwise.circle,weight=semibold,colour1=#51a3ef,colour2=#5154ef" \
        --button1text "Restart Now" \
        --button2text "Later" \
        --width 500 \
        --height 300 2>/dev/null
    
    rc=$?
    
    if [[ ${rc} -eq 0 ]]; then
        notice "User chose to restart now"
        info "Executing restart in 5 seconds..."
        sleep 5
        /sbin/shutdown -r now
    else
        notice "User chose to restart later"
    fi
}



####################################################################################################
#
# Main Program
#
####################################################################################################

notice "SYM-Lite initialized successfully"
notice "Configuration: ${#installomatorItems[@]} Installomator items, ${#jamfPolicyItems[@]} Jamf policy items"
notice "Operation mode: ${operationMode}"

# Phase 2: Show selection dialog
showSelectionDialog
separateSelectedItemsByType

# Phase 3 & 4: Execute selected items via Inspect Mode
executeSYMLiteItems

# Phase 5: Display completion and prompt for restart
showCompletionDialog
promptForRestart

info "SYM-Lite execution complete - Total Elapsed Time: $(formattedElapsedTime)"
quitScript 0
