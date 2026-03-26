#!/bin/zsh --no-rcs
# shellcheck shell=bash
# ShellCheck has no zsh mode; bash parser is used for baseline linting.

####################################################################################################
#
# Microsoft 365 Reset
#
# Unified swiftDialog-driven replacement for expanded Office-Reset package workflows.
#
# https://snelson.us
#
####################################################################################################
#
# HISTORY
#
# Version 0.0.1a8, 25-Mar-2026, Dan K. Snelson
#  - Expanded `remove_acrobat_addin` cleanup targets to cover Startup and Startup.localized variants
#  - Wait for Word, Excel, PowerPoint, and Acrobat to quit before interactive Acrobat add-in removal
#
# Version 0.0.1a7, 25-Mar-2026, Dan K. Snelson
#  - Added `remove_acrobat_addin` as a standalone Adobe Acrobat add-in removal operation
#
# Version 0.0.1a6, 25-Mar-2026, Dan K. Snelson
#  - Added resolved operation summary to `startProgressDialog()`
#  - Wait for the background progress dialog to close before continuing
#  - Suppressed `swiftDialog` stderr for captured JSON dialogs
#
# Version 0.0.1a5, 18-Mar-2026, Dan K. Snelson
#  - Enabled moveable and minimizable window for `startProgressDialog()`
#
# Version 0.0.1a4, 18-Mar-2026, Dan K. Snelson
#   - Improved Jamf parameter handling to skip all leading positionals regardless of count
#
# Version 0.0.1a3, 14-Mar-2026, Dan K. Snelson
#   - Fixed argument parsing so Jamf-style leading positional parameters no longer trigger `Unknown argument` before CLI flags are processed (Addresses [Issue #3](https://github.com/dan-snelson/Microsoft-365-Reset/issues/3); thanks for the heads-up, @eirikt!)
#
# Version 0.0.1a2, 13-Mar-2026, Dan K. Snelson
#   - Aligned cleanup targets with MOFA community-maintained reset scripts
#   - Added MOFA-style factory reset cleanup and Teams reset behavior
#   - Skip app configuration cleanup after repair/reinstall to match MOFA app reset scripts
#   - Added license-only reset and Teams force-reinstall operations
#
# Version 0.0.1a1, 12-Mar-2026, Dan K. Snelson
#   - Initial unified script implementation
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
setopt NONOMATCH

# Script identity
scriptVersion="0.0.1a8"
humanReadableScriptName="Microsoft 365 Reset"
scriptName="M365R"

# Dialog presentation defaults
fontSize="14"

# Organization-specific overlay icon URL
organizationOverlayiconURL="https://swiftdialog.app/_astro/dialog_logo.CZF0LABZ_ZjWz8w.webp"

autoload -Uz is-at-least

# swiftDialog requirement and install paths
swiftDialogMinimumRequiredVersion="3.0.0.4952"
dialogBinary="/usr/local/bin/dialog"

# Runtime inputs (Jamf parameters by default; CLI flags can override below)
operationMode="${4:-self-service}"
operationCSV="${5:-}"

# Client-side Log
scriptLog="/var/log/org.churchofjesuschrist.log"
restartMode="Restart Confirm"

# CLI flags override Jamf parameters; skip all leading positionals until we see a CLI flag
seenCLIFlag="false"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            seenCLIFlag="true"
            if [[ -z "${2:-}" || "${2}" == -* ]]; then
                echo "Missing or invalid value for --mode. Usage: $0 [--mode MODE] [--operations CSV]"
                exit 10
            fi
            operationMode="$2"
            shift 2
            ;;
        --operations)
            seenCLIFlag="true"
            if [[ -z "${2:-}" || "${2}" == -* ]]; then
                echo "Missing or invalid value for --operations. Usage: $0 [--mode MODE] [--operations CSV]"
                exit 10
            fi
            operationCSV="$2"
            shift 2
            ;;
        --*)
            echo "Unknown argument: $1"
            exit 10
            ;;
        *)
            if [[ "${seenCLIFlag}" == "false" ]]; then
                shift
                continue
            fi
            echo "Unknown argument: $1"
            exit 10
            ;;
    esac
done

case "${operationMode:l}" in
    debug)
        operationMode="debug"
        set -x
        ;;
    self\ service)
        operationMode="self-service"
        ;;
    self-service|silent|test)
        operationMode="${operationMode:l}"
        ;;
    *)
        echo "Invalid mode '${operationMode}'"
        exit 10
        ;;
esac

# Runtime work files and operation result tracking
SECONDS="0"
workDirectory="$(mktemp -d /private/tmp/${scriptName}.XXXXXX)"
chmod 755 "${workDirectory}" 2>/dev/null
dialogCommandFile="$(mktemp /var/tmp/dialogCommandFile_${scriptName}.XXXX)"
chmod 644 "${dialogCommandFile}" 2>/dev/null
selectedOperations=()
resolvedOperations=()
failedOperations=()
completedOperations=()
dialogPID=""

# Logged-in user context (resolved during preflight)
loggedInUser=""
loggedInUserFullname=""
loggedInUserID=""
loggedInUserHome=""
loggedInUserHomeDirectory=""

# Operation metadata used by selection UI and validation
operationIDs=(
    reset_factory
    reset_word
    reset_excel
    reset_powerpoint
    reset_outlook
    remove_outlook_data
    reset_onenote
    remove_onenote_data
    reset_onedrive
    reset_teams
    reset_teams_force
    reset_autoupdate
    reset_license
    reset_credentials
    remove_office
    remove_skypeforbusiness
    remove_defender
    remove_acrobat_addin
    remove_zoomplugin
    remove_webexpt
)

typeset -A operationTitle
operationTitle[reset_factory]="Reset Office apps to factory settings"
operationTitle[reset_word]="Reset Word"
operationTitle[reset_excel]="Reset Excel"
operationTitle[reset_powerpoint]="Reset PowerPoint"
operationTitle[reset_outlook]="Reset Outlook"
operationTitle[remove_outlook_data]="Remove cached Outlook data"
operationTitle[reset_onenote]="Reset OneNote"
operationTitle[remove_onenote_data]="Remove cached OneNote data"
operationTitle[reset_onedrive]="Reset OneDrive"
operationTitle[reset_teams]="Reset Teams"
operationTitle[reset_teams_force]="Reset Teams (Force Reinstall)"
operationTitle[reset_autoupdate]="Reset AutoUpdate"
operationTitle[reset_license]="Reset License Only"
operationTitle[reset_credentials]="Reset License and Sign-In"
operationTitle[remove_office]="Completely remove Microsoft 365"
operationTitle[remove_skypeforbusiness]="Remove Skype for Business"
operationTitle[remove_defender]="Remove Defender"
operationTitle[remove_acrobat_addin]="Remove Adobe Acrobat Add-in"
operationTitle[remove_zoomplugin]="Remove Zoom Outlook Plugin"
operationTitle[remove_webexpt]="Remove WebEx Productivity Tools"

typeset -A operationDescription
operationDescription[reset_factory]="Closes all Office apps, checks for damage and performs repairs as necessary. Resets caches, keychains, templates, add-ins and configuration data. This will not remove your personal documents."
operationDescription[reset_word]="Closes Microsoft Word, checks for damage and performs repairs as necessary. Resets caches, templates, add-ins and configuration data. This will not remove your personal documents."
operationDescription[reset_excel]="Closes Microsoft Excel, checks for damage and performs repairs as necessary. Resets caches, templates, add-ins and configuration data. This will not remove your personal workbooks."
operationDescription[reset_powerpoint]="Closes Microsoft PowerPoint, checks for damage and performs repairs as necessary. Resets caches, templates, add-ins and configuration data. This will not remove your personal presentations."
operationDescription[reset_outlook]="Closes Microsoft Outlook, checks for damage and performs repairs as necessary. Resets caches, credentials, templates, add-ins and configuration data."
operationDescription[remove_outlook_data]="Closes Microsoft Outlook and removes all mailbox data. Warning: This will remove all local mailbox data."
operationDescription[reset_onenote]="Closes Microsoft OneNote, checks for damage and performs repairs as necessary. Resets caches, local synchronized content and configuration data."
operationDescription[remove_onenote_data]="Closes Microsoft OneNote and removes cached data. Warning: This will remove any content that has not synchronized with the cloud."
operationDescription[reset_onedrive]="Closes Microsoft OneDrive, checks for damage and performs repairs as necessary. Resets caches and configuration data. This will not remove your synchronized OneDrive files."
operationDescription[reset_teams]="Closes Microsoft Teams, checks for damage and performs repairs as necessary. Resets caches, credentials and configuration data."
operationDescription[reset_teams_force]="Closes Microsoft Teams, removes the current Teams app bundle, reinstalls the latest version, and then resets Teams caches, credentials and configuration data."
operationDescription[reset_autoupdate]="Resets Microsoft AutoUpdate to default settings and installs the latest version of the tool."
operationDescription[reset_license]="Closes all apps and removes Office licensing files plus core Office identity data without the broader Teams and OneDrive sign-in cleanup."
operationDescription[reset_credentials]="Closes all apps and removes the Office license files. Sign-in credentials and cached tokens are removed from keychain."
operationDescription[remove_office]="Removes all Microsoft 365 and Office apps, components, add-ins, templates and configuration data."
operationDescription[remove_skypeforbusiness]="Closes Microsoft Skype for Business and then removes the application, configuration data, and keychain items."
operationDescription[remove_defender]="Closes Microsoft Defender and then removes the application, configuration data, and keychain items."
operationDescription[remove_acrobat_addin]="Removes the Adobe Acrobat add-in files for Word, Excel, and PowerPoint."
operationDescription[remove_zoomplugin]="Removes the Zoom Plugin for Outlook and associated metadata."
operationDescription[remove_webexpt]="Removes WebEx Productivity Tools associated metadata."

autoRepairOps=(reset_word reset_excel reset_powerpoint reset_outlook reset_onenote reset_onedrive reset_teams reset_autoupdate)



####################################################################################################
#
# Logging Helpers
#
####################################################################################################

function updateScriptLog() {
    local level="$1"
    local message="$2"
    echo "${scriptName} (${scriptVersion}): $(date '+%Y-%m-%d %H:%M:%S')  [${level}] ${message}" | tee -a "${scriptLog}" >&2
}
function preFlight() { updateScriptLog "PRE-FLIGHT" "${1}"; }
function notice()    { updateScriptLog "NOTICE" "${1}"; }
function info()      { updateScriptLog "INFO" "${1}"; }
function warning()   { updateScriptLog "WARNING" "${1}"; }
function errorOut()  { updateScriptLog "ERROR" "${1}"; }
function fatal()     { updateScriptLog "FATAL ERROR" "${1}"; exit 10; }

function cleanup() {
    rm -f "${dialogCommandFile}" 2>/dev/null
    rm -rf "${workDirectory}" 2>/dev/null
}
trap cleanup EXIT



####################################################################################################
#
# Core Helpers
#
####################################################################################################

function getLoggedInUser() {
    local consoleUser
    consoleUser="$(/bin/echo 'show State:/Users/ConsoleUser' | /usr/sbin/scutil | /usr/bin/awk '/Name :/&&!/loginwindow/{print $3}')"
    if [[ -n "${consoleUser}" && "${consoleUser}" != "root" ]]; then
        echo "${consoleUser}"
    else
        echo ""
    fi
}

function setHomeFolder() {
    local targetUser="$1"
    local homePath
    homePath="$(dscl . read /Users/"${targetUser}" NFSHomeDirectory 2>/dev/null | awk -F': ' '/NFSHomeDirectory/{print $2}')"
    if [[ -z "${homePath}" ]]; then
        if [[ -d "/Users/${targetUser}" ]]; then
            homePath="/Users/${targetUser}"
        else
            homePath="$(eval echo ~"${targetUser}")"
        fi
    fi
    echo "${homePath}"
}

function runAsUser() {
    local user="$1"
    shift
    local userID=""
    local rc=0

    if [[ -z "${user}" ]]; then
        "$@"
        return $?
    fi

    userID="$(id -u "${user}" 2>/dev/null)"
    if [[ "${userID}" =~ ^[0-9]+$ ]]; then
        /bin/launchctl asuser "${userID}" /usr/bin/sudo -u "${user}" "$@"
        rc=$?
        [[ ${rc} -eq 0 ]] && return 0
    fi

    /usr/bin/sudo -u "${user}" "$@"
}

function safeRemove() {
    local targetPath="$1"

    if [[ -z "${targetPath}" || "${targetPath}" == "/" ]]; then
        warning "safeRemove refused unsafe path: '${targetPath}'"
        return 1
    fi

    if [[ -e "${targetPath}" || -L "${targetPath}" ]]; then
        /bin/rm -rf "${targetPath}" >>"${scriptLog}" 2>&1
        local rmStatus=$?
        if [[ ${rmStatus} -ne 0 ]]; then
            warning "Failed to remove path: ${targetPath}"
            return ${rmStatus}
        fi
    fi

    return 0
}

function hasOperation() {
    local op="$1"
    local item
    for item in "${selectedOperations[@]}"; do
        [[ "${item}" == "${op}" ]] && return 0
    done
    return 1
}

function addOperationUnique() {
    local op="$1"
    if ! hasOperation "${op}"; then
        selectedOperations+=("${op}")
    fi
}

function isOperationSelected() {
    local op="$1"
    local item
    for item in "${resolvedOperations[@]}"; do
        [[ "${item}" == "${op}" ]] && return 0
    done
    return 1
}

function appendFailure() {
    local op="$1"
    failedOperations+=("${op}")
}

function appendCompletion() {
    local op="$1"
    completedOperations+=("${op}")
}

function findKeychainDB() {
    local userHome="$1"
    find "${userHome}/Library/Keychains" -name keychain-2.db -print -quit 2>/dev/null
}

function findEntryGenericByLabel() {
    local label="$1"
    local user="${2:-}"
    if [[ -n "${user}" ]]; then
        runAsUser "${user}" /usr/bin/security find-generic-password -l "${label}" >/dev/null 2>&1
    else
        /usr/bin/security find-generic-password -l "${label}" >/dev/null 2>&1
    fi
}

function findEntryGenericByService() {
    local service="$1"
    local user="${2:-}"
    if [[ -n "${user}" ]]; then
        runAsUser "${user}" /usr/bin/security find-generic-password -s "${service}" >/dev/null 2>&1
    else
        /usr/bin/security find-generic-password -s "${service}" >/dev/null 2>&1
    fi
}

function findEntryGenericByCreator() {
    local creator="$1"
    local user="${2:-}"
    if [[ -n "${user}" ]]; then
        runAsUser "${user}" /usr/bin/security find-generic-password -G "${creator}" >/dev/null 2>&1
    else
        /usr/bin/security find-generic-password -G "${creator}" >/dev/null 2>&1
    fi
}

function deleteGenericByLabel() {
    local label="$1"
    local user="${2:-}"
    if [[ -n "${user}" ]]; then
        runAsUser "${user}" /usr/bin/security delete-generic-password -l "${label}" >>"${scriptLog}" 2>&1
    else
        /usr/bin/security delete-generic-password -l "${label}" >>"${scriptLog}" 2>&1
    fi
}

function deleteGenericByService() {
    local service="$1"
    local user="${2:-}"
    if [[ -n "${user}" ]]; then
        runAsUser "${user}" /usr/bin/security delete-generic-password -s "${service}" >>"${scriptLog}" 2>&1
    else
        /usr/bin/security delete-generic-password -s "${service}" >>"${scriptLog}" 2>&1
    fi
}

function deleteInternetByService() {
    local service="$1"
    local user="${2:-}"
    if [[ -n "${user}" ]]; then
        runAsUser "${user}" /usr/bin/security delete-internet-password -s "${service}" >>"${scriptLog}" 2>&1
    else
        /usr/bin/security delete-internet-password -s "${service}" >>"${scriptLog}" 2>&1
    fi
}

function deleteGenericByCreator() {
    local creator="$1"
    local user="${2:-}"
    if [[ -n "${user}" ]]; then
        runAsUser "${user}" /usr/bin/security delete-generic-password -G "${creator}" >>"${scriptLog}" 2>&1
    else
        /usr/bin/security delete-generic-password -G "${creator}" >>"${scriptLog}" 2>&1
    fi
}

function deleteGenericByLabelLoop() {
    local label="$1"
    local user="${2:-}"
    while findEntryGenericByLabel "${label}" "${user}"; do
        deleteGenericByLabel "${label}" "${user}" || break
    done
}

function deleteGenericByCreatorLoop() {
    local creator="$1"
    local user="${2:-}"
    while findEntryGenericByCreator "${creator}" "${user}"; do
        deleteGenericByCreator "${creator}" "${user}" || break
    done
}

function ensureLoginKeychainPresent() {
    local user="$1"
    local home="$2"
    local keychains
    keychains="$(runAsUser "${user}" /usr/bin/security list-keychains 2>/dev/null)"
    if [[ "${keychains}" != *"login.keychain"* ]]; then
        runAsUser "${user}" /usr/bin/security list-keychains -s "${home}/Library/Keychains/login.keychain-db" >>"${scriptLog}" 2>&1
    fi
}

function getPrefValue() {
    local domain="$1"
    local key="$2"
    osascript -l JavaScript <<EOS
ObjC.import('Foundation');
ObjC.unwrap($.NSUserDefaults.alloc.initWithSuiteName('${domain}').objectForKey('${key}'))
EOS
}

function verifyMicrosoftPkgSignature() {
    local pkgPath="$1"
    local signing
    signing="$(/usr/sbin/pkgutil --check-signature "${pkgPath}" 2>/dev/null | awk -F': ' '/Developer ID Installer/{print $2}' | awk '{$1=$1};1')"
    [[ "${signing}" == "Microsoft Corporation (UBF8T346G9)" ]]
}

function downloadResolvedPkgURL() {
    local url="$1"
    /usr/bin/nscurl --location --head "${url}" --dump-header - 2>/dev/null \
        | grep -i '^Location:' \
        | tail -1 \
        | awk -F': ' '{print $2}' \
        | tr -d '\r'
}

function contentLengthForURL() {
    local url="$1"
    /usr/bin/nscurl --location --head "${url}" --dump-header - 2>/dev/null \
        | grep -i '^Content-Length:' \
        | tail -1 \
        | awk -F': ' '{print $2}' \
        | tr -d '\r'
}

function repairFromMicrosoftPkg() {
    local appName="$1"
    local downloadURL="$2"
    local explicitPkgURL="$3"

    local downloadFolder="/Users/Shared/OnDemandInstaller/"
    local pkgURL=""
    local pkgName=""
    local expectedSize=""
    local localSize=""

    rm -rf "${downloadFolder}" >>"${scriptLog}" 2>&1
    mkdir -p "${downloadFolder}" >>"${scriptLog}" 2>&1

    if [[ -n "${explicitPkgURL}" ]]; then
        pkgURL="${explicitPkgURL}"
    else
        pkgURL="$(downloadResolvedPkgURL "${downloadURL}")"
    fi

    if [[ -z "${pkgURL}" ]]; then
        errorOut "Unable to resolve download URL for ${appName}"
        return 1
    fi

    pkgName="$(basename "${pkgURL}")"
    expectedSize="$(contentLengthForURL "${pkgURL}")"

    info "Starting package download for ${appName}: ${pkgURL}"
    /usr/bin/nscurl --download --large-download --location --download-directory "${downloadFolder}" "${pkgURL}" >>"${scriptLog}" 2>&1 || return 1

    if [[ ! -f "${downloadFolder}${pkgName}" ]]; then
        errorOut "Downloaded package missing for ${appName}"
        return 1
    fi

    if [[ -n "${expectedSize}" ]]; then
        localSize="$(stat -qf%z "${downloadFolder}${pkgName}" 2>/dev/null)"
        if [[ -n "${localSize}" && "${localSize}" != "${expectedSize}" ]]; then
            errorOut "Malformed package download for ${appName}; expected ${expectedSize}, got ${localSize}"
            return 1
        fi
    fi

    if ! verifyMicrosoftPkgSignature "${downloadFolder}${pkgName}"; then
        errorOut "Package signature check failed for ${appName}"
        return 1
    fi

    info "Installing package for ${appName}"
    /usr/sbin/installer -pkg "${downloadFolder}${pkgName}" -target / >>"${scriptLog}" 2>&1
}

function resolveCustomManifest() {
    local manifestProductID="$1"
    local channelName
    local manifestServer
    local fullUpdater
    local customVersion

    channelName="$(getPrefValue "com.microsoft.autoupdate2" "ChannelName" 2>/dev/null)"
    if [[ "${channelName}" != "Custom" ]]; then
        echo "|"
        return 0
    fi

    manifestServer="$(getPrefValue "com.microsoft.autoupdate2" "ManifestServer" 2>/dev/null)"
    if [[ -z "${manifestServer}" ]]; then
        echo "|"
        return 0
    fi

    fullUpdater="$(/usr/bin/nscurl --location "${manifestServer}/0409${manifestProductID}.xml" 2>/dev/null | grep -A1 -m1 'FullUpdaterLocation' | grep 'string' | sed -e 's,.*<string>\([^<]*\)</string>.*,\1,g')"
    customVersion=""
    if [[ "${fullUpdater}" == https://* ]]; then
        customVersion="$(/usr/bin/nscurl --location "${manifestServer}/0409${manifestProductID}-chk.xml" 2>/dev/null | grep -A1 -m1 'Update Version' | grep 'string' | sed -e 's,.*<string>\([^<]*\)</string>.*,\1,g')"
    fi

    echo "${fullUpdater}|${customVersion}"
}

function maybeRepairOfficeApp() {
    local appName="$1"
    local appPath="$2"
    local download2019="$3"
    local download2016="$4"
    local manifestProductID="$5"
    local osVersion="$6"

    local appVersion
    local appGeneration="2019"
    local customInfo
    local fullUpdater
    local customVersion
    local codesignError
    local repairPerformed="false"

    if [[ ! -d "${appPath}" ]]; then
        info "${appName} not found in default location"
        return 0
    fi

    appVersion="$(defaults read "${appPath}/Contents/Info.plist" CFBundleVersion 2>/dev/null)"
    info "Found ${appName} version ${appVersion}"

    if ! is-at-least 16.17 "${appVersion}"; then
        appGeneration="2016"
    fi

    if [[ "${appGeneration}" == "2019" ]]; then
        if ! is-at-least 16.73 "${appVersion}" && is-at-least 11.0.0 "${osVersion}"; then
            info "${appName} is outdated; repairing"
            repairFromMicrosoftPkg "${appName}" "${download2019}" "" || return 1
            repairPerformed="true"
        fi

        customInfo="$(resolveCustomManifest "${manifestProductID}")"
        fullUpdater="${customInfo%%|*}"
        customVersion="${customInfo##*|}"
        if [[ -n "${customVersion}" && "${appVersion}" != "${customVersion}" ]]; then
            info "${appName} pinned version mismatch (${appVersion} != ${customVersion}); reinstalling"
            safeRemove "${appPath}"
            repairFromMicrosoftPkg "${appName}" "${download2019}" "${fullUpdater}" || return 1
            repairPerformed="true"
        fi
    else
        if ! is-at-least 16.16 "${appVersion}"; then
            info "${appName} legacy generation outdated; repairing"
            repairFromMicrosoftPkg "${appName}" "${download2016}" "" || return 1
            repairPerformed="true"
        fi
    fi

    /usr/bin/codesign -vv --deep "${appPath}" >>"${scriptLog}" 2>&1
    if [[ $? -ne 0 ]]; then
        codesignError="$(/usr/bin/codesign -vv --deep "${appPath}" 2>&1)"
        if [[ "${codesignError}" == *"OLE.framework"* ]]; then
            warning "${appName} codesign mismatch limited to OLE.framework; proceeding"
        else
            warning "${appName} app bundle damaged; reinstalling"
            safeRemove "${appPath}"
            if [[ "${appGeneration}" == "2016" ]]; then
                repairFromMicrosoftPkg "${appName}" "${download2016}" "" || return 1
            else
                customInfo="$(resolveCustomManifest "${manifestProductID}")"
                fullUpdater="${customInfo%%|*}"
                repairFromMicrosoftPkg "${appName}" "${download2019}" "${fullUpdater}" || return 1
            fi
            repairPerformed="true"
        fi
    fi

    if [[ "${repairPerformed}" == "true" ]]; then
        info "${appName} repair completed; skipping configuration cleanup to match MOFA behavior"
        return 2
    fi

    return 0
}


####################################################################################################
#
# swiftDialog Helpers
#
####################################################################################################

function dialogInstall() {
    local dialogURL
    local expectedTeamID="PWA5E9TQ59"
    local tempPkgDir

    dialogURL="$(curl -L --silent --fail --connect-timeout 10 --max-time 30 \
        "https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest" \
        | awk -F '"' '/browser_download_url/ && /pkg"/ {print $4; exit}')"

    [[ -n "${dialogURL}" ]] || fatal "Failed to retrieve swiftDialog download URL"
    [[ "${dialogURL}" == https://github.com/* ]] || fatal "Invalid swiftDialog URL: ${dialogURL}"

    tempPkgDir="$(mktemp -d /private/tmp/dialog-install.XXXXXX)"

    if ! curl -L --silent --fail --connect-timeout 10 --max-time 60 "${dialogURL}" -o "${tempPkgDir}/Dialog.pkg"; then
        rm -rf "${tempPkgDir}"
        fatal "Failed to download swiftDialog package"
    fi

    local teamID
    teamID="$(spctl -a -vv -t install "${tempPkgDir}/Dialog.pkg" 2>&1 | awk -F'[()]' '/origin=/{print $2}' | tr -d ' ')"
    if [[ "${teamID}" != "${expectedTeamID}" ]]; then
        rm -rf "${tempPkgDir}"
        fatal "swiftDialog package team ID mismatch: ${teamID}"
    fi

    /usr/sbin/installer -pkg "${tempPkgDir}/Dialog.pkg" -target / >>"${scriptLog}" 2>&1 || {
        rm -rf "${tempPkgDir}"
        fatal "swiftDialog installation failed"
    }

    rm -rf "${tempPkgDir}"
}

function dialogCheck() {
    if [[ ! -x "${dialogBinary}" ]]; then
        preFlight "swiftDialog binary not found; installing"
        dialogInstall
    fi

    local installedVersion
    installedVersion="$(${dialogBinary} --version 2>/dev/null | awk '{print $NF}' | tr -d '()')"
    if [[ -z "${installedVersion}" ]]; then
        preFlight "Unable to read swiftDialog version; reinstalling"
        dialogInstall
        installedVersion="$(${dialogBinary} --version 2>/dev/null | awk '{print $NF}' | tr -d '()')"
    fi

    if ! is-at-least "${swiftDialogMinimumRequiredVersion}" "${installedVersion}"; then
        preFlight "swiftDialog ${installedVersion} is below required ${swiftDialogMinimumRequiredVersion}; upgrading"
        dialogInstall
    fi
}

function writeDialogCommand() {
    local line="$1"
    if [[ -f "${dialogCommandFile}" ]]; then
        echo "${line}" >> "${dialogCommandFile}"
    fi
}

function formattedElapsedTime() {
    printf '%dh:%dm:%ds' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60))
}

function showIntroDialog() {
    [[ "${operationMode}" == "silent" ]] && return 0

    ${dialogBinary} \
        --title "${humanReadableScriptName}" \
        --infotext "${scriptVersion}" \
        --messagefont "size=${fontSize}" \
        --message "This tool _may_ help address Microsoft 365-related issues on this Mac:\n- Repair\n- Reset\n- Remove\n\nClick **Continue** to select actions; click **Cancel** to exit." \
        --icon "https://usw2.ics.services.jamfcloud.com/icon/hash_8bf6549c22de3db831aafaf9c5c02d3aa9a928f4abe377eb2f8cbeab3959615c" \
        --overlayicon "${organizationOverlayiconURL}" \
        --button1text "Continue" \
        --button2text "Cancel" \
        --quitkey q

    local rc=$?
    if [[ ${rc} -ne 0 ]]; then
        info "User '${loggedInUser}' cancelled intro dialog"
        exit 2
    fi
}

function parseOperationCSV() {
    local csv="$1"
    selectedOperations=()
    [[ -z "${csv}" ]] && return 0

    local oldIFS="$IFS"
    IFS=','
    local op
    for op in ${csv}; do
        op="${op// /}"
        [[ -z "${op}" ]] && continue
        addOperationUnique "${op}"
    done
    IFS="${oldIFS}"
}

function parseDialogSelections() {
    local output="$1"
    selectedOperations=()

    local op
    for op in "${operationIDs[@]}"; do
        if echo "${output}" | grep -Eiq "${op}\"?[[:space:]]*:[[:space:]]*(true|1|yes)"; then
            selectedOperations+=("${op}")
        fi
    done

    # Fallback for JSON output
    if [[ ${#selectedOperations[@]} -eq 0 ]] && command -v jq >/dev/null 2>&1; then
        for op in "${operationIDs[@]}"; do
            if echo "${output}" | jq -e ".${op} == true" >/dev/null 2>&1; then
                selectedOperations+=("${op}")
            fi
        done
    fi
}

function showSelectionDialog() {
    if [[ "${operationMode}" == "silent" ]]; then
        parseOperationCSV "${operationCSV}"
        return 0
    fi

    local checkboxArgs=()
    local op
    local baseMessage
    local warningMessage=""
    local messageText
    local dialogOutput
    local rc

    for op in "${operationIDs[@]}"; do
        checkboxArgs+=(--checkbox "${operationTitle[${op}]},name=${op}")
    done

    baseMessage="Select one or more reset / removal operations.\n\nNote: Choosing **Completely remove Microsoft 365** suppresses reset-related actions."

    while true; do
        messageText="${baseMessage}"
        if [[ -n "${warningMessage}" ]]; then
            messageText="${messageText}\n\n:red[${warningMessage}]"
        fi

        dialogOutput="$(${dialogBinary} \
            --title "${humanReadableScriptName}" \
            --infotext "${scriptVersion}" \
            --messagefont "size=${fontSize}" \
            --message "${messageText}" \
            --icon "https://usw2.ics.services.jamfcloud.com/icon/hash_a0bc0557b531bc5d2713dece4f513df1ac5038ff55ebf5115edf43b951f916c7" \
            --checkboxstyle "switch,small" \
            --json \
            --button1text "Run" \
            --button2text "Cancel" \
            "${checkboxArgs[@]}" 2>/dev/null)"

        rc=$?
        if [[ ${rc} -ne 0 ]]; then
            info "User '${loggedInUser}' cancelled selection dialog"
            exit 2
        fi

        parseDialogSelections "${dialogOutput}"
        if [[ ${#selectedOperations[@]} -gt 0 ]]; then
            return 0
        fi

        warning "No operations selected in picker; re-showing selection dialog"
        warningMessage="**Warning:** Please select at least _one_ option before clicking **Run**."
    done
}

function resolveDependencies() {
    local op

    if hasOperation "reset_factory"; then
        addOperationUnique reset_word
        addOperationUnique reset_excel
        addOperationUnique reset_powerpoint
        addOperationUnique reset_outlook
        addOperationUnique reset_onenote
        addOperationUnique reset_onedrive
        addOperationUnique reset_teams
        addOperationUnique reset_autoupdate
        addOperationUnique reset_credentials
    fi

    if hasOperation "reset_credentials"; then
        local retained=()
        for op in "${selectedOperations[@]}"; do
            case "${op}" in
                reset_license)
                    ;;
                *)
                    retained+=("${op}")
                    ;;
            esac
        done
        selectedOperations=("${retained[@]}")
        addOperationUnique reset_credentials
    fi

    if hasOperation "reset_teams_force"; then
        local retained=()
        for op in "${selectedOperations[@]}"; do
            case "${op}" in
                reset_teams)
                    ;;
                *)
                    retained+=("${op}")
                    ;;
            esac
        done
        selectedOperations=("${retained[@]}")
        addOperationUnique reset_teams_force
    fi

    if hasOperation "remove_office"; then
        addOperationUnique remove_skypeforbusiness

        # remove_office suppresses reset-family selections to match Distribution behavior.
        local retained=()
        for op in "${selectedOperations[@]}"; do
            case "${op}" in
                reset_factory|reset_word|reset_excel|reset_powerpoint|reset_outlook|reset_onenote|reset_onedrive|reset_teams|reset_teams_force|reset_autoupdate|reset_license|reset_credentials)
                    ;;
                *)
                    retained+=("${op}")
                    ;;
            esac
        done
        selectedOperations=("${retained[@]}")
        addOperationUnique remove_office
        addOperationUnique remove_skypeforbusiness
    fi

    resolvedOperations=("${selectedOperations[@]}")
}

function confirmDestructiveSelection() {
    local requiresConfirmation="false"
    isOperationSelected remove_office && requiresConfirmation="true"
    isOperationSelected remove_outlook_data && requiresConfirmation="true"
    isOperationSelected remove_onenote_data && requiresConfirmation="true"

    [[ "${requiresConfirmation}" == "false" ]] && return 0
    [[ "${operationMode}" == "silent" ]] && return 0

    ${dialogBinary} \
        --title "Confirm Destructive Actions" \
        --infotext "${scriptVersion}" \
        --messagefont "size=${fontSize}" \
        --message "**:red[Warning:]** You selected one or more destructive actions that can permanently remove local data.\n\nConfirm to proceed." \
        --icon "SF=exclamationmark.triangle, weight=bold, colour1=red" \
        --checkbox "I understand these actions are destructive,name=confirm_destructive,enableButton1" \
        --json \
        --button1text "Confirm" \
        --button1disabled \
        --button2text "Cancel" > "${workDirectory}/destructive.json" 2>/dev/null

    local rc=$?
    if [[ ${rc} -ne 0 ]]; then
        info "User '${loggedInUser}' cancelled destructive confirmation"
        exit 2
    fi

    if ! grep -Eiq 'confirm_destructive\"?[[:space:]]*:[[:space:]]*(true|1|yes)' "${workDirectory}/destructive.json"; then
        info "Destructive confirmation checkbox not acknowledged"
        exit 2
    fi
}

function startProgressDialog() {
    [[ "${operationMode}" == "silent" ]] && return 0

    local progressMessage

    : > "${dialogCommandFile}"
    chmod 644 "${dialogCommandFile}" 2>/dev/null
    if [[ -n "${loggedInUser}" ]]; then
        /usr/sbin/chown "${loggedInUser}" "${dialogCommandFile}" 2>/dev/null
    fi

    progressMessage="$(progressDialogMessage)"

    ${dialogBinary} \
        --title "${humanReadableScriptName}" \
        --infotext "${scriptVersion}" \
        --messagefont "size=${fontSize}" \
        --message "${progressMessage}" \
        --icon "SF=gearshape.2.fill, weight=bold, colour1=#FF7D08, colour2=#FF0810" \
        --moveable \
        --windowbuttons "min" \
        --commandfile "${dialogCommandFile}" \
        --button1disabled \
        --progress 100 \
        --progresstext "Starting ..." &

    dialogPID=$!
    sleep 1
}

function progressDialogMessage() {
    local message="The following operations will run:"
    local op

    if [[ ${#resolvedOperations[@]} -eq 0 ]]; then
        echo "Running selected operations ..."
        return 0
    fi

    for op in "${resolvedOperations[@]}"; do
        message="${message}\n- ${operationTitle[${op}]}"
    done

    echo "${message}"
}

function waitForProgressDialog() {
    [[ "${operationMode}" == "silent" ]] && return 0

    if [[ -n "${dialogPID}" ]]; then
        wait "${dialogPID}" 2>/dev/null || true
        dialogPID=""
    fi
}

function updateProgressDialog() {
    local current="$1"
    local total="$2"
    local progressStatus="$3"
    [[ "${operationMode}" == "silent" ]] && return 0

    local completed=$(( current - 1 ))
    local pct=$(( ( completed * 100 ) / total ))
    writeDialogCommand "progress: ${pct}"
    writeDialogCommand "progresstext: ${progressStatus}"
}

function updateCompletedProgressDialog() {
    local current="$1"
    local total="$2"
    local progressStatus="$3"
    [[ "${operationMode}" == "silent" ]] && return 0

    local pct=$(( ( current * 100 ) / total ))
    writeDialogCommand "progress: ${pct}"
    writeDialogCommand "progresstext: ${progressStatus}"
}

function finishProgressDialog() {
    [[ "${operationMode}" == "silent" ]] && return 0
    writeDialogCommand "progress: complete"
    writeDialogCommand "button1text: Done"
    writeDialogCommand "button1: enable"
    writeDialogCommand "progresstext: Completed"
    sleep 1
    writeDialogCommand "quit:"
    waitForProgressDialog
}

function showCompletionDialog() {
    [[ "${operationMode}" == "silent" ]] && return 0

    local summary="**Results**<br><br>- Completed operations: ${#completedOperations[@]}<br>- Failed operations: ${#failedOperations[@]}<br>- Elapsed Time: $(formattedElapsedTime)"

    if [[ ${#failedOperations[@]} -gt 0 ]]; then
        summary+="<br><br>Failed IDs: ${failedOperations[*]}"
    fi

    ${dialogBinary} \
        --title "${humanReadableScriptName}" \
        --infotext "${scriptVersion}" \
        --messagefont "size=${fontSize}" \
        --message "${summary}" \
        --icon "SF=checkmark.circle.fill, weight=bold, colour1=#00ff44, colour2=#075c1e" \
        --button1text "Close"
}

function executeRestartAction() {
    local effectiveRestartMode="${1:-${restartMode}}"
    local restartCommand=""

    case "${effectiveRestartMode}" in
        Restart)
            restartCommand="sleep 1 && shutdown -r now &"
            if /bin/zsh -c "${restartCommand}" >>"${scriptLog}" 2>&1; then
                notice "Restart command '${effectiveRestartMode}' sent as root: ${restartCommand}"
                return 0
            fi
            warning "Failed to invoke restart command '${effectiveRestartMode}' as root: ${restartCommand}"
            return 1
            ;;
        "Restart Confirm"|*)
            if runAsUser "${loggedInUser}" /usr/bin/osascript -e 'tell app "loginwindow" to «event aevtrrst»' >>"${scriptLog}" 2>&1; then
                notice "Restart command '${effectiveRestartMode}' sent for ${loggedInUser}."
                return 0
            fi
            warning "Failed to invoke restart command '${effectiveRestartMode}' for ${loggedInUser}."
            return 1
            ;;
    esac
}

function promptForRestart() {
    [[ "${operationMode}" == "silent" ]] && return 0

    ${dialogBinary} \
        --title "Restart Recommended" \
        --infotext "${scriptVersion}" \
        --messagefont "size=${fontSize}" \
        --message "To ensure all changes are fully applied, restart this Mac now." \
        --icon "SF=restart.circle.fill, colour=#1C1A1A" \
        --button1text "Restart Now" \
        --button2text "Later"

    local restartPromptRC=$?
    if [[ ${restartPromptRC} -eq 0 ]]; then
        info "User opted to restart now"
        executeRestartAction "Restart Confirm"
    else
        info "User deferred restart"
    fi
}


####################################################################################################
#
# Operation Helpers
#
####################################################################################################

function waitForInteractiveAppQuit() {
    local processName="$1"
    local appName="$2"
    local appIcon="$3"

    [[ "${operationMode}" == "silent" ]] && return 0

    if ! pgrep -x "${processName}" >/dev/null 2>&1; then
        info "${appName} not running; proceeding"
        return 0
    fi

    info "Waiting for ${appName} to quit before continuing"

    [[ -n "${appIcon}" ]] && writeDialogCommand "icon: ${appIcon}"
    writeDialogCommand "message: Please save open files and quit ${appName}."
    writeDialogCommand "progresstext: Waiting for ${loggedInUser} to quit ${appName} ..."

    while pgrep -x "${processName}" >/dev/null 2>&1; do
        sleep 1
    done

    writeDialogCommand "message: ${appName} is no longer running."
    writeDialogCommand "progresstext: Continuing ..."
}

function prepareForAcrobatAddinRemoval() {
    if [[ "${operationMode}" == "silent" ]]; then
        info "Silent mode: force-stopping Word, Excel, PowerPoint, and Acrobat before add-in removal"
        pkill -9 'Microsoft Word' 2>/dev/null
        pkill -9 'Microsoft Excel' 2>/dev/null
        pkill -9 'Microsoft PowerPoint' 2>/dev/null
        pkill -9 'AdobeAcrobat' 2>/dev/null
        return 0
    fi

    writeDialogCommand "message: Please quit Word, Excel, PowerPoint, and Acrobat before removal."
    writeDialogCommand "progresstext: Verifying required apps are closed ..."

    waitForInteractiveAppQuit "Microsoft Word" "Microsoft Word" "/Applications/Microsoft Word.app"
    waitForInteractiveAppQuit "Microsoft Excel" "Microsoft Excel" "/Applications/Microsoft Excel.app"
    waitForInteractiveAppQuit "Microsoft PowerPoint" "Microsoft PowerPoint" "/Applications/Microsoft PowerPoint.app"
    waitForInteractiveAppQuit "AdobeAcrobat" "Adobe Acrobat" "/Applications/Adobe Acrobat DC/Adobe Acrobat.app"

    writeDialogCommand "icon: SF=gearshape.2.fill, weight=bold, colour1=#FF7D08, colour2=#FF0810"
    writeDialogCommand "message: Removing Adobe Acrobat add-in payloads ..."
    writeDialogCommand "progresstext: Removing Adobe Acrobat add-in payloads ..."
}

function stopCommonOfficeProcesses() {
    pkill -9 'Microsoft Word' 2>/dev/null
    pkill -9 'Microsoft Excel' 2>/dev/null
    pkill -9 'Microsoft PowerPoint' 2>/dev/null
    pkill -9 'Microsoft Outlook' 2>/dev/null
    pkill -9 'Microsoft OneNote' 2>/dev/null
    pkill -9 'OneDrive' 2>/dev/null
    pkill -9 'OneDrive Finder Integration' 2>/dev/null
    pkill -9 'FinderSync' 2>/dev/null
    pkill -9 'OneDriveStandaloneUpdater' 2>/dev/null
    pkill -9 'OneDriveUpdater' 2>/dev/null
    pkill -9 'MSTeams' 2>/dev/null
    pkill -9 'Microsoft Teams' 2>/dev/null
    pkill -9 'Microsoft Teams Helper' 2>/dev/null
    pkill -9 'Microsoft Teams WebView' 2>/dev/null
    pkill -9 'Microsoft Teams Launcher' 2>/dev/null
    pkill -9 'Microsoft Teams (work preview)' 2>/dev/null
    pkill -9 'Microsoft Teams*' 2>/dev/null
    pkill -9 'Microsoft AutoUpdate' 2>/dev/null
    pkill -9 'Microsoft Update Assistant' 2>/dev/null
    pkill -9 'Microsoft AU Daemon' 2>/dev/null
    pkill -9 'Microsoft AU Bootstrapper' 2>/dev/null
    pkill -9 'com.microsoft.autoupdate.helper' 2>/dev/null
    pkill -9 'com.microsoft.autoupdate.helpertool' 2>/dev/null
    pkill -9 'com.microsoft.autoupdate.bootstrapper.helper' 2>/dev/null
}

function removeOfficePreinstall() {
    info "Running Remove Office preinstall sequence"

    stopCommonOfficeProcesses

    launchctl stop /Library/LaunchAgents/com.microsoft.update.agent.plist 2>/dev/null
    launchctl stop /Library/LaunchAgents/com.microsoft.autoupdate.helper.plist 2>/dev/null
    launchctl stop /Library/LaunchAgents/com.microsoft.OneDriveStandaloneUpdater.plist 2>/dev/null
    launchctl stop /Library/LaunchAgents/com.microsoft.SyncReporter.plist 2>/dev/null
    launchctl stop /Library/LaunchDaemons/com.microsoft.autoupdate.helper 2>/dev/null
    launchctl stop /Library/LaunchDaemons/com.microsoft.autoupdate.helper.plist 2>/dev/null
    launchctl stop /Library/LaunchDaemons/com.microsoft.OneDriveUpdaterDaemon.plist 2>/dev/null
    launchctl stop /Library/LaunchDaemons/com.microsoft.teams.TeamsUpdaterDaemon.plist 2>/dev/null

    launchctl unload /Library/LaunchAgents/com.microsoft.update.agent.plist 2>/dev/null
    launchctl unload /Library/LaunchAgents/com.microsoft.autoupdate.helper.plist 2>/dev/null
    launchctl unload /Library/LaunchAgents/com.microsoft.OneDriveStandaloneUpdater.plist 2>/dev/null
    launchctl unload /Library/LaunchDaemons/com.microsoft.autoupdate.helper 2>/dev/null
    launchctl unload /Library/LaunchDaemons/com.microsoft.autoupdate.helper.plist 2>/dev/null
    launchctl unload /Library/LaunchDaemons/com.microsoft.OneDriveUpdaterDaemon.plist 2>/dev/null
    launchctl unload /Library/LaunchDaemons/com.microsoft.teams.TeamsUpdaterDaemon.plist 2>/dev/null

    safeRemove "/Applications/Microsoft Word.app"
    safeRemove "/Applications/Microsoft Excel.app"
    safeRemove "/Applications/Microsoft PowerPoint.app"
    safeRemove "/Applications/Microsoft Outlook.app"
    safeRemove "/Applications/Microsoft OneNote.app"
    safeRemove "/Applications/OneDrive.app"
    safeRemove "/Applications/Microsoft Teams.app"
    safeRemove "/Applications/Microsoft Teams classic.app"
    safeRemove "/Applications/Microsoft Teams (work or school).app"
    rm -rf /Applications/CodeSignSummary-*.md >>"${scriptLog}" 2>&1

    safeRemove "/Library/Application Support/Microsoft/MAU2.0"
    safeRemove "/Library/Application Support/Microsoft/MERP2.0"
    safeRemove "/Library/Application Support/Microsoft/Office365"
    safeRemove "${loggedInUserHome}/Library/Application Support/Microsoft"

    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.errorreporting"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.OneDrive.FinderSync"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.OneDrive.FileProvider"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.com.microsoft.oneauth"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.OfficeOneDriveSyncIntegration"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.Office"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.OneDriveStandaloneSuite"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.OneDriveSyncClientSuite"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.ms"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.Kfm"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.OfficeOsfWebHost"

    safeRemove "/Library/LaunchAgents/com.microsoft.update.agent.plist"
    safeRemove "/Library/LaunchAgents/com.microsoft.OneDriveStandaloneUpdater.plist"
    safeRemove "/Library/LaunchAgents/com.microsoft.SyncReporter.plist"

    safeRemove "/Library/LaunchDaemons/com.microsoft.autoupdate.helper.plist"
    safeRemove "/Library/LaunchDaemons/com.microsoft.office.licensingV2.helper.plist"
    safeRemove "/Library/LaunchDaemons/com.microsoft.OneDriveStandaloneUpdaterDaemon.plist"
    safeRemove "/Library/LaunchDaemons/com.microsoft.OneDriveUpdaterDaemon.plist"
    safeRemove "/Library/LaunchDaemons/com.microsoft.teams.TeamsUpdaterDaemon.plist"

    safeRemove "/Library/PrivilegedHelperTools/com.microsoft.autoupdate.helper"
    safeRemove "/Library/PrivilegedHelperTools/com.microsoft.autoupdate.helpertool"
    safeRemove "/Library/PrivilegedHelperTools/com.microsoft.office.licensingV2.helper"

    safeRemove "/Library/Audio/Plug-Ins/HAL/MSTeamsAudioDevice.driver"
    safeRemove "/Library/Logs/Microsoft"
    safeRemove "${loggedInUserHome}/Library/Logs/Microsoft"

    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.autoupdate2.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.autoupdate.fba.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.shared.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.office.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.Word.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.Excel.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.Powerpoint.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.Outlook.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.onenote.mac.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.OneDrive-mac.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.OneDrive.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.teams.plist"

    safeRemove "/Library/Preferences/com.microsoft.autoupdate2.plist"
    safeRemove "/Library/Preferences/com.microsoft.autoupdate.fba.plist"
    safeRemove "/Library/Preferences/com.microsoft.shared.plist"
    safeRemove "/Library/Preferences/com.microsoft.office.plist"
    safeRemove "/Library/Preferences/com.microsoft.Word.plist"
    safeRemove "/Library/Preferences/com.microsoft.Excel.plist"
    safeRemove "/Library/Preferences/com.microsoft.Powerpoint.plist"
    safeRemove "/Library/Preferences/com.microsoft.Outlook.plist"
    safeRemove "/Library/Preferences/com.microsoft.onenote.mac.plist"
    safeRemove "/Library/Preferences/com.microsoft.OneDrive-mac.plist"
    safeRemove "/Library/Preferences/com.microsoft.OneDrive.plist"
    safeRemove "/Library/Preferences/com.microsoft.teams.plist"

    safeRemove "/Library/Managed Preferences/com.microsoft.shared.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.office.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.Word.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.Excel.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.Powerpoint.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.Outlook.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.onenote.mac.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.OneDrive-mac.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.OneDrive.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.teams.plist"

    safeRemove "/var/root/Library/Preferences/com.microsoft.autoupdate2.plist"
    safeRemove "/var/root/Library/Preferences/com.microsoft.autoupdate.fba.plist"

    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.autoupdate2"
    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.autoupdate.fba"
    safeRemove "${loggedInUserHome}/Library/Caches/Microsoft"

    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.OfficeOneDriveSyncIntegration"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.ms"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.OneDriveStandaloneSuite"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.OneDriveSyncClientSuite"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Kfm"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.OfficeOsfWebHost"
    safeRemove "${loggedInUserHome}/Library/Group Containers/group.com.microsoft"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.com.microsoft.oneauth"

    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.errorreporting"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.netlib.shipassertprocess"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.OneDrive-mac"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.OneDrive.FinderSync"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.OneDrive-mac.FinderSync"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.OneDriveLauncher"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.OneDrive.FileProvider"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.Office365ServiceV2"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.RMS-XPCService"

    local remainingApps=()
    local appPath
    local expectedRemovedApps=(
        "/Applications/Microsoft Word.app"
        "/Applications/Microsoft Excel.app"
        "/Applications/Microsoft PowerPoint.app"
        "/Applications/Microsoft Outlook.app"
        "/Applications/Microsoft OneNote.app"
        "/Applications/Microsoft Teams.app"
        "/Applications/Microsoft Teams classic.app"
        "/Applications/Microsoft Teams (work or school).app"
        "/Applications/OneDrive.app"
    )

    for appPath in "${expectedRemovedApps[@]}"; do
        if [[ -d "${appPath}" ]]; then
            remainingApps+=("${appPath}")
        fi
    done

    if [[ ${#remainingApps[@]} -gt 0 ]]; then
        errorOut "Remove Office preinstall left app bundles in place: ${remainingApps[*]}"
        return 1
    fi

    return 0
}

function removeOfficePostinstall() {
    info "Running Remove Office postinstall sequence"

    local receipts=(
        com.microsoft.Word
        com.microsoft.Excel
        com.microsoft.Powerpoint
        com.microsoft.Outlook
        com.microsoft.onenote.mac
        com.microsoft.OneDrive-mac
        com.microsoft.package.Microsoft_Word.app
        com.microsoft.package.Microsoft_Excel.app
        com.microsoft.package.Microsoft_PowerPoint.app
        com.microsoft.package.Microsoft_Outlook.app
        com.microsoft.package.Microsoft_OneNote.app
        com.microsoft.package.Microsoft_AutoUpdate.app
        com.microsoft.package.Microsoft_AU_Bootstrapper.app
        com.microsoft.package.com.microsoft.office.licensingV2.helper
        com.microsoft.package.Proofing_Tools
        com.microsoft.package.Fonts
        com.microsoft.package.DFonts
        com.microsoft.package.Frameworks
        com.microsoft.pkg.licensing
        com.microsoft.pkg.licensing.volume
        com.microsoft.office.licensingV2.helper
        com.microsoft.teams
        com.microsoft.teams2
        com.microsoft.MSTeamsAudioDevice
        com.microsoft.wdav
        com.microsoft.OneDrive
    )

    local receipt
    for receipt in "${receipts[@]}"; do
        /usr/sbin/pkgutil --forget "${receipt}" >>"${scriptLog}" 2>&1
    done

    safeRemove "/Library/Preferences/com.microsoft.office.licensingV2.backup"
    safeRemove "/Library/Preferences/com.microsoft.autoupdate2.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.autoupdate2.plist"

    safeRemove "${loggedInUserHome}/Library/Cookies/com.microsoft.OneDrive.binarycookies"
    safeRemove "${loggedInUserHome}/Library/Cookies/com.microsoft.OneDriveUpdater.binarycookies"
    safeRemove "${loggedInUserHome}/Library/Cookies/com.microsoft.OneDriveStandaloneUpdater.binarycookies"
    safeRemove "${loggedInUserHome}/Library/Cookies/com.microsoft.teams.binarycookies"

    safeRemove "/Library/Logs/Microsoft"
    safeRemove "/Library/Application Support/Microsoft"
    safeRemove "/Users/Shared/OnDemandInstaller"
}

function registerMAUApplicationIfPresent() {
    local appPath="$1"
    local appIDNew="$2"
    local appIDOld="$3"

    if [[ -d "${appPath}" ]]; then
        local appVersion
        appVersion="$(defaults read "${appPath}/Contents/Info.plist" CFBundleVersion 2>/dev/null)"
        if [[ -n "${appVersion}" ]]; then
            if is-at-least 16.17 "${appVersion}"; then
                defaults write /Library/Preferences/com.microsoft.autoupdate2 ApplicationsSystem -dict-add "${appPath}" "{ 'Application ID' = '${appIDNew}'; LCID = 1033 ; 'App Domain' = 'com.microsoft.office' ; }" >>"${scriptLog}" 2>&1
            else
                defaults write /Library/Preferences/com.microsoft.autoupdate2 ApplicationsSystem -dict-add "${appPath}" "{ 'Application ID' = '${appIDOld}'; LCID = 1033 ; 'App Domain' = 'com.microsoft.office' ; }" >>"${scriptLog}" 2>&1
            fi
        fi
    fi
}

function registerMAUStaticApplicationIfPresent() {
    local appPath="$1"
    local appMetadata="$2"

    if [[ -d "${appPath}" ]]; then
        defaults write /Library/Preferences/com.microsoft.autoupdate2 ApplicationsSystem -dict-add "${appPath}" "${appMetadata}" >>"${scriptLog}" 2>&1
    fi
}


####################################################################################################
#
# Operation Implementations
#
####################################################################################################

function cleanupFactoryResetArtifacts() {
    safeRemove "/Library/Logs/Microsoft/autoupdate.log"
    safeRemove "/Library/Logs/Microsoft/InstallLogs"
    safeRemove "/Library/Logs/Microsoft/Teams"
    safeRemove "/Library/Logs/Microsoft/OneDrive"

    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.autoupdate2.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.autoupdate.fba.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.shared.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.office.plist"
    safeRemove "/Library/Preferences/com.microsoft.autoupdate.fba.plist"
    safeRemove "/Library/Preferences/com.microsoft.shared.plist"
    safeRemove "/Library/Preferences/com.microsoft.office.plist"
    safeRemove "/Library/Preferences/com.microsoft.teams.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.shared.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.office.plist"
    safeRemove "/var/root/Library/Preferences/com.microsoft.autoupdate2.plist"
    safeRemove "/var/root/Library/Preferences/com.microsoft.autoupdate.fba.plist"

    safeRemove "${loggedInUserHome}/Library/Application Support/Microsoft"
    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.autoupdate2"
    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.autoupdate.fba"
    safeRemove "/Library/Application Support/Microsoft/Office365"

    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.ms"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.OfficeOsfWebHost"

    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.com.microsoft.oneauth"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.Office"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.ms"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.OfficeOsfWebHost"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.OfficeOneDriveSyncIntegration"

    safeRemove "${loggedInUserHome}/Library/Cookies/com.microsoft.OneDrive.binarycookies"
    safeRemove "${loggedInUserHome}/Library/Cookies/com.microsoft.OneDriveUpdater.binarycookies"
    safeRemove "${loggedInUserHome}/Library/Cookies/com.microsoft.OneDriveStandaloneUpdater.binarycookies"
    safeRemove "${loggedInUserHome}/Library/Cookies/com.microsoft.teams.binarycookies"

    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.autoupdate.fba"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.autoupdate2"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.OneDrive"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.OneDriveStandaloneUpdater"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.teams"

    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.autoupdate.fba.binarycookies"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.autoupdate2.binarycookies"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.OneDrive.binarycookies"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.OneDriveStandaloneUpdater.binarycookies"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.teams.binarycookies"

    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.errorreporting"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.netlib.shipassertprocess"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.Office365ServiceV2"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.RMS-XPCService"
}

function op_reset_factory() {
    info "Starting operation: reset_factory"
    stopCommonOfficeProcesses
    pkill -9 'Microsoft Teams Helper' 2>/dev/null
    pkill -9 'com.microsoft.teams2.launcher' 2>/dev/null
    cleanupFactoryResetArtifacts
    return 0
}

function cleanupOfficeCommonGroupContainers() {
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/mip_policy"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/FontCache"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/ComRPC32"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/TemporaryItems"
    rm -f "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office"/Microsoft\ Office\ ACL* >>"${scriptLog}" 2>&1
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/MicrosoftRegistrationDB.reg"
}

function op_reset_word() {
    info "Starting operation: reset_word"
    local osVersion
    osVersion="$(sw_vers -productVersion)"

    pkill -9 'Microsoft Word' 2>/dev/null

    maybeRepairOfficeApp \
        "Microsoft Word" \
        "/Applications/Microsoft Word.app" \
        "https://go.microsoft.com/fwlink/?linkid=525134" \
        "https://go.microsoft.com/fwlink/?linkid=871748" \
        "MSWD2019" \
        "${osVersion}"
    local repairRC=$?
    [[ ${repairRC} -eq 1 ]] && return 1
    [[ ${repairRC} -eq 2 ]] && return 0

    safeRemove "/Library/Preferences/com.microsoft.Word.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.Word.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.Word.plist"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.Word"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.Word"
    safeRemove "/Applications/.Microsoft Word.app.installBackup"

    safeRemove "/Library/Application Support/Microsoft/Office365/User Content.localized/Startup.localized/Word"
    rm -rf "/Library/Application Support/Microsoft/Office365/User Content.localized/Templates.localized"/*.dot >>"${scriptLog}" 2>&1
    rm -rf "/Library/Application Support/Microsoft/Office365/User Content.localized/Templates.localized"/*.dotx >>"${scriptLog}" 2>&1
    rm -rf "/Library/Application Support/Microsoft/Office365/User Content.localized/Templates.localized"/*.dotm >>"${scriptLog}" 2>&1

    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Startup.localized/Word"
    rm -rf "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Templates.localized"/*.dot >>"${scriptLog}" 2>&1
    rm -rf "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Templates.localized"/*.dotx >>"${scriptLog}" 2>&1
    rm -rf "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Templates.localized"/*.dotm >>"${scriptLog}" 2>&1

    cleanupOfficeCommonGroupContainers

    safeRemove "${TMPDIR}/com.microsoft.Word"
    return 0
}

function op_reset_excel() {
    info "Starting operation: reset_excel"
    local osVersion
    osVersion="$(sw_vers -productVersion)"

    pkill -9 'Microsoft Excel' 2>/dev/null

    maybeRepairOfficeApp \
        "Microsoft Excel" \
        "/Applications/Microsoft Excel.app" \
        "https://go.microsoft.com/fwlink/?linkid=525135" \
        "https://go.microsoft.com/fwlink/?linkid=871750" \
        "XCEL2019" \
        "${osVersion}"
    local repairRC=$?
    [[ ${repairRC} -eq 1 ]] && return 1
    [[ ${repairRC} -eq 2 ]] && return 0

    safeRemove "/Library/Preferences/com.microsoft.Excel.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.Excel.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.Excel.plist"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.Excel"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.Excel"
    safeRemove "/Applications/.Microsoft Excel.app.installBackup"

    safeRemove "/Library/Application Support/Microsoft/Office365/User Content.localized/Startup.localized/Excel"
    rm -rf "/Library/Application Support/Microsoft/Office365/User Content.localized/Templates.localized"/*.xlt >>"${scriptLog}" 2>&1
    rm -rf "/Library/Application Support/Microsoft/Office365/User Content.localized/Templates.localized"/*.xltx >>"${scriptLog}" 2>&1
    rm -rf "/Library/Application Support/Microsoft/Office365/User Content.localized/Templates.localized"/*.xltm >>"${scriptLog}" 2>&1

    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Startup.localized/Excel"
    rm -rf "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Templates.localized"/*.xlt >>"${scriptLog}" 2>&1
    rm -rf "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Templates.localized"/*.xltx >>"${scriptLog}" 2>&1
    rm -rf "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Templates.localized"/*.xltm >>"${scriptLog}" 2>&1

    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/mip_policy"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/ComRPC32"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/TemporaryItems"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/MicrosoftRegistrationDB.reg"

    /usr/bin/security delete-certificate -c 'Microsoft.Office.Excel.ProtectedDataServices' >>"${scriptLog}" 2>&1

    safeRemove "${TMPDIR}/com.microsoft.Excel"
    return 0
}

function op_reset_powerpoint() {
    info "Starting operation: reset_powerpoint"
    local osVersion
    osVersion="$(sw_vers -productVersion)"

    pkill -9 'Microsoft PowerPoint' 2>/dev/null

    maybeRepairOfficeApp \
        "Microsoft PowerPoint" \
        "/Applications/Microsoft PowerPoint.app" \
        "https://go.microsoft.com/fwlink/?linkid=525136" \
        "https://go.microsoft.com/fwlink/?linkid=871751" \
        "PPT32019" \
        "${osVersion}"
    local repairRC=$?
    [[ ${repairRC} -eq 1 ]] && return 1
    [[ ${repairRC} -eq 2 ]] && return 0

    safeRemove "/Library/Preferences/com.microsoft.Powerpoint.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.Powerpoint.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.Powerpoint.plist"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.Powerpoint"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.Powerpoint"
    safeRemove "/Applications/.Microsoft PowerPoint.app.installBackup"

    safeRemove "/Library/Application Support/Microsoft/Office365/User Content.localized/Startup.localized/PowerPoint"
    rm -rf "/Library/Application Support/Microsoft/Office365/User Content.localized/Templates.localized"/*.pot >>"${scriptLog}" 2>&1
    rm -rf "/Library/Application Support/Microsoft/Office365/User Content.localized/Templates.localized"/*.potx >>"${scriptLog}" 2>&1
    rm -rf "/Library/Application Support/Microsoft/Office365/User Content.localized/Templates.localized"/*.potm >>"${scriptLog}" 2>&1

    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Startup.localized/PowerPoint"
    rm -rf "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Templates.localized"/*.pot >>"${scriptLog}" 2>&1
    rm -rf "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Templates.localized"/*.potx >>"${scriptLog}" 2>&1
    rm -rf "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Templates.localized"/*.potm >>"${scriptLog}" 2>&1

    rm -rf "/Library/Application Support/Microsoft/Office365/User Content.localized/Add-Ins"/*.ppam >>"${scriptLog}" 2>&1
    rm -rf "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Add-Ins"/*.ppam >>"${scriptLog}" 2>&1
    safeRemove "/Library/Application Support/Microsoft/Office365/User Content.localized/Themes"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Themes"

    cleanupOfficeCommonGroupContainers
    safeRemove "${TMPDIR}/com.microsoft.Powerpoint"

    return 0
}

function op_reset_outlook() {
    info "Starting operation: reset_outlook"
    local osVersion
    osVersion="$(sw_vers -productVersion)"

    pkill -9 'Microsoft Outlook' 2>/dev/null

    maybeRepairOfficeApp \
        "Microsoft Outlook" \
        "/Applications/Microsoft Outlook.app" \
        "https://go.microsoft.com/fwlink/?linkid=525137" \
        "https://go.microsoft.com/fwlink/?linkid=871753" \
        "OPIM2019" \
        "${osVersion}"
    local repairRC=$?
    [[ ${repairRC} -eq 1 ]] && return 1
    [[ ${repairRC} -eq 2 ]] && return 0

    safeRemove "/Library/Preferences/com.microsoft.Outlook.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.Outlook.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.Outlook.plist"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.Outlook"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.Outlook.CalendarWidget"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.Outlook"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.Outlook.CalendarWidget"

    safeRemove "/Library/Application Support/Microsoft/WebExPlugin"
    safeRemove "/Library/Application Support/Microsoft/ZoomOutlookPlugin"
    safeRemove "/Users/Shared/ZoomOutlookPlugin"

    safeRemove "/Library/Application Support/Microsoft/Office365/User Content.localized/Startup.localized/Word/NormalEmail.dotm"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Startup.localized/Word/NormalEmail.dotm"

    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/DRM_Evo.plist"
    cleanupOfficeCommonGroupContainers

    safeRemove "${TMPDIR}/com.microsoft.Outlook"
    safeRemove "/Applications/.Microsoft Outlook.app.installBackup"

    ensureLoginKeychainPresent "${loggedInUser}" "${loggedInUserHome}"

    deleteInternetByService 'msoCredentialSchemeADAL' "${loggedInUser}"
    deleteInternetByService 'msoCredentialSchemeLiveId' "${loggedInUser}"

    deleteGenericByCreatorLoop 'MSOpenTech.ADAL.1' "${loggedInUser}"

    deleteGenericByLabel 'Microsoft Office Identities Cache 2' "${loggedInUser}"
    deleteGenericByLabel 'Microsoft Office Identities Cache 3' "${loggedInUser}"
    deleteGenericByLabel 'Microsoft Office Identities Settings 2' "${loggedInUser}"
    deleteGenericByLabel 'Microsoft Office Identities Settings 3' "${loggedInUser}"
    deleteGenericByLabel 'Microsoft Office Ticket Cache' "${loggedInUser}"
    deleteGenericByLabel 'Microsoft Office Ticket Cache 2' "${loggedInUser}"
    deleteGenericByLabel 'com.microsoft.adalcache' "${loggedInUser}"
    deleteGenericByLabel 'com.microsoft.OutlookCore.Secret' "${loggedInUser}"

    deleteGenericByLabelLoop 'com.helpshift.data_com.microsoft.Outlook' "${loggedInUser}"
    deleteGenericByLabelLoop 'MicrosoftOfficeRMSCredential' "${loggedInUser}"
    deleteGenericByLabelLoop 'MSProtection.framework.service' "${loggedInUser}"
    deleteGenericByLabelLoop 'Exchange' "${loggedInUser}"

    return 0
}

function op_remove_outlook_data() {
    info "Starting operation: remove_outlook_data"

    pkill -9 'Microsoft Outlook' 2>/dev/null
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.Outlook.plist"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/Outlook"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/OutlookProfile.plist"

    return 0
}

function op_reset_onenote() {
    info "Starting operation: reset_onenote"
    local osVersion
    osVersion="$(sw_vers -productVersion)"

    pkill -9 'Microsoft OneNote' 2>/dev/null

    maybeRepairOfficeApp \
        "Microsoft OneNote" \
        "/Applications/Microsoft OneNote.app" \
        "https://go.microsoft.com/fwlink/?linkid=820886" \
        "https://go.microsoft.com/fwlink/?linkid=871755" \
        "ONMC2019" \
        "${osVersion}"
    local repairRC=$?
    [[ ${repairRC} -eq 1 ]] && return 1
    [[ ${repairRC} -eq 2 ]] && return 0

    safeRemove "/Library/Preferences/com.microsoft.onenote.mac.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.onenote.mac.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.onenote.mac.plist"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.onenote.mac"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.onenote.mac.shareextension"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.onenote.mac"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.onenote.mac.shareextension"

    safeRemove "/Applications/.Microsoft OneNote.app.installBackup"

    # Handle both the canonical and legacy typo team IDs found in source scripts
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/OneNote"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/FontCache"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/TemporaryItems"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T369G9.Office/OneNote"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T369G9.Office/FontCache"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T369G9.Office/TemporaryItems"

    return 0
}

function op_remove_onenote_data() {
    info "Starting operation: remove_onenote_data"

    pkill -9 'Microsoft OneNote' 2>/dev/null
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.onenote.mac"

    return 0
}

function op_reset_onedrive() {
    info "Starting operation: reset_onedrive"
    local osVersion
    osVersion="$(sw_vers -productVersion)"

    pkill -9 'OneDrive' 2>/dev/null
    pkill -9 'FinderSync' 2>/dev/null
    pkill -9 'OneDriveStandaloneUpdater' 2>/dev/null
    pkill -9 'OneDriveUpdater' 2>/dev/null

    if [[ -d "/Applications/OneDrive.app" ]]; then
        local oneDriveVersion
        oneDriveVersion="$(defaults read /Applications/OneDrive.app/Contents/Info.plist CFBundleVersion 2>/dev/null)"
        if ! is-at-least 23154.0 "${oneDriveVersion}" && is-at-least 10.15 "${osVersion}"; then
            repairFromMicrosoftPkg "Microsoft OneDrive" "https://go.microsoft.com/fwlink/?linkid=861011" "" || return 1
        fi

        /usr/bin/codesign -vv --deep /Applications/OneDrive.app >>"${scriptLog}" 2>&1
        if [[ $? -ne 0 ]]; then
            safeRemove "/Applications/OneDrive.app"
            repairFromMicrosoftPkg "Microsoft OneDrive" "https://go.microsoft.com/fwlink/?linkid=861011" "" || return 1
        fi
    fi

    safeRemove "${loggedInUserHome}/Library/Caches/OneDrive"
    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.OneDrive"
    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.OneDriveUpdater"
    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.OneDriveStandaloneUpdater"
    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.SyncReporter"
    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.SharePoint-mac"

    safeRemove "${loggedInUserHome}/Library/Cookies/com.microsoft.OneDrive.binarycookies"
    safeRemove "${loggedInUserHome}/Library/Cookies/com.microsoft.OneDriveUpdater.binarycookies"
    safeRemove "${loggedInUserHome}/Library/Cookies/com.microsoft.OneDriveStandaloneUpdater.binarycookies"

    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.OneDrive"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.OneDrive.binarycookies"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.OneDriveUpdater"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.OneDriveUpdater.binarycookies"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.SharePoint-mac"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.SharePoint-mac.binarycookies"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.SyncReporter"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.SyncReporter.binarycookies"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.OneDriveStandaloneUpdater"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.OneDriveStandaloneUpdater.binarycookies"

    safeRemove "${loggedInUserHome}/Library/WebKit/com.microsoft.OneDrive"

    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.OneDrive-mac"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.OneDrive.FinderSync"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.OneDrive-mac.FinderSync"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.OneDriveLauncher"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.OneDrive.FileProvider"

    safeRemove "${loggedInUserHome}/Library/Logs/OneDrive"
    safeRemove "/Library/Logs/Microsoft/OneDrive"

    safeRemove "${loggedInUserHome}/Library/Application Support/OneDrive"
    safeRemove "${loggedInUserHome}/Library/Application Support/com.microsoft.OneDrive"
    safeRemove "${loggedInUserHome}/Library/Application Support/com.microsoft.OneDriveUpdater"
    safeRemove "${loggedInUserHome}/Library/Application Support/com.microsoft.OneDriveStandaloneUpdater"
    safeRemove "${loggedInUserHome}/Library/Application Support/com.microsoft.SharePoint-mac"
    safeRemove "${loggedInUserHome}/Library/Application Support/OneDriveUpdater"
    safeRemove "${loggedInUserHome}/Library/Application Support/OneDriveStandaloneUpdater"

    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.OneDrive.FinderSync"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.OneDrive.FileProvider"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.OneDriveStandaloneSuite"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.OfficeOneDriveSyncIntegration"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.OneDriveSyncClientSuite"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.Kfm"

    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.OfficeOneDriveSyncIntegration"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.OneDriveStandaloneSuite"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.OneDriveSyncClientSuite"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Kfm"

    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.OneDrive.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.SharePoint-mac.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.OneDriveStandaloneUpdater.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.OneDriveUpdater.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/UBF8T346G9.OneDriveStandaloneSuite.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/UBF8T346G9.OfficeOneDriveSyncIntegration.plist"

    safeRemove "/Library/Preferences/com.microsoft.OneDrive.plist"
    safeRemove "/Library/Preferences/com.microsoft.OneDriveStandaloneUpdater.plist"
    safeRemove "/Library/Preferences/com.microsoft.OneDriveUpdater.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.OneDriveStandaloneUpdater.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.OneDriveUpdater.plist"

    safeRemove "${TMPDIR}/com.microsoft.OneDrive"
    safeRemove "${TMPDIR}/com.microsoft.OneDrive.FinderSync"
    safeRemove "${TMPDIR}/OneDriveVersion.xml"

    ensureLoginKeychainPresent "${loggedInUser}" "${loggedInUserHome}"

    deleteGenericByLabel 'com.microsoft.OneDrive.FinderSync.HockeySDK' "${loggedInUser}"
    deleteGenericByLabel 'com.microsoft.OneDrive.HockeySDK' "${loggedInUser}"
    deleteGenericByLabel 'com.microsoft.OneDriveUpdater.HockeySDK' "${loggedInUser}"
    deleteGenericByLabel 'com.microsoft.OneDriveStandaloneUpdater.HockeySDK' "${loggedInUser}"
    deleteGenericByLabel 'OneDrive Standalone Cached Credential Business - Business1' "${loggedInUser}"
    deleteGenericByLabel 'OneDrive Standalone Cached Credential' "${loggedInUser}"
    deleteGenericByService 'com.microsoft.onedrive.cookies' "${loggedInUser}"
    deleteGenericByService 'OneAuthAccount' "${loggedInUser}"
    deleteGenericByLabel 'com.microsoft.adalcache' "${loggedInUser}"

    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.com.microsoft.oneauth"

    local keychainDB
    keychainDB="$(findKeychainDB "${loggedInUserHome}")"
    if [[ -n "${keychainDB}" ]]; then
        /usr/bin/sqlite3 "${keychainDB}" "DELETE FROM genp WHERE agrp='UBF8T346G9.com.microsoft.identity.universalstorage';" >>"${scriptLog}" 2>&1
    fi

    return 0
}

function resetTeamsOperation() {
    local forceReinstall="${1:-false}"
    local osVersion
    local teamsAppPath="/Applications/Microsoft Teams.app"
    local classicTeamsPath="/Applications/Microsoft Teams classic.app"
    local workOrSchoolTeamsPath="/Applications/Microsoft Teams (work or school).app"
    local teamsPkgURL="https://go.microsoft.com/fwlink/?linkid=2249065"
    local classicBackgroundsPath="${loggedInUserHome}/Library/Application Support/Microsoft/Teams/Backgrounds"
    local modernBackgroundsPath="${loggedInUserHome}/Library/Containers/com.microsoft.teams2/Data/Library/Application Support/Microsoft/MSTeams/Backgrounds"
    local modernBackgroundsStaging="/tmp/${scriptName}_Teams_Backgrounds"
    local teamsBackgroundArchive="${loggedInUserHome}/Teams_Old_Backgrounds"
    local installAttempt=1
    local installationRetries=5
    local shouldInstallTeams="false"
    osVersion="$(sw_vers -productVersion)"

    pkill -9 'MSTeams' 2>/dev/null
    pkill -9 'Microsoft Teams' 2>/dev/null
    pkill -9 'Microsoft Teams Helper' 2>/dev/null
    pkill -9 'Microsoft Teams WebView' 2>/dev/null
    pkill -9 'Microsoft Teams Launcher' 2>/dev/null
    pkill -9 'Microsoft Teams (work preview)' 2>/dev/null
    pkill -9 'Microsoft Teams*' 2>/dev/null

    if [[ -d "${teamsAppPath}" ]]; then
        local currentTeamsVersion
        currentTeamsVersion="$(defaults read "${teamsAppPath}/Contents/Info.plist" CFBundleVersion 2>/dev/null)"
        info "Found Microsoft Teams version ${currentTeamsVersion}"
        if [[ "${forceReinstall}" == "true" ]]; then
            info "Force reinstall requested for Microsoft Teams; removing existing app bundle"
            safeRemove "${teamsAppPath}"
            shouldInstallTeams="true"
        elif ! is-at-least 23247.0 "${currentTeamsVersion}" && is-at-least 10.15 "${osVersion}"; then
            info "Installed Microsoft Teams is below MOFA minimum; removing for reinstall"
            safeRemove "${teamsAppPath}"
            shouldInstallTeams="true"
        fi
    fi

    if [[ "${forceReinstall}" == "true" && -d "${classicTeamsPath}" ]]; then
        info "Force reinstall requested for Microsoft Teams; removing classic Teams app bundle"
        safeRemove "${classicTeamsPath}"
        shouldInstallTeams="true"
    fi

    if [[ "${forceReinstall}" == "true" && -d "${workOrSchoolTeamsPath}" ]]; then
        info "Force reinstall requested for Microsoft Teams; removing Teams work-or-school app bundle"
        safeRemove "${workOrSchoolTeamsPath}"
        shouldInstallTeams="true"
    fi

    if [[ -d "${classicBackgroundsPath}" ]]; then
        local originalArchivePath="${teamsBackgroundArchive}"
        local archiveCounter=0
        while [[ -e "${teamsBackgroundArchive}" ]]; do
            ((archiveCounter++))
            teamsBackgroundArchive="${originalArchivePath}${archiveCounter}"
        done
        /bin/mv "${classicBackgroundsPath}" "${teamsBackgroundArchive}" >>"${scriptLog}" 2>&1
        /usr/sbin/chown -R "${loggedInUser}" "${teamsBackgroundArchive}" >>"${scriptLog}" 2>&1
        if [[ "${operationMode}" != "silent" ]]; then
            runAsUser "${loggedInUser}" /usr/bin/open "${teamsBackgroundArchive}" >>"${scriptLog}" 2>&1
        fi
    fi

    if [[ -d "${modernBackgroundsPath}" ]]; then
        [[ -e "${modernBackgroundsStaging}" ]] && rm -rf "${modernBackgroundsStaging}" >>"${scriptLog}" 2>&1
        /bin/mv "${modernBackgroundsPath}" "${modernBackgroundsStaging}" >>"${scriptLog}" 2>&1
    fi

    safeRemove "${loggedInUserHome}/Library/Application Support/Teams"
    safeRemove "${loggedInUserHome}/Library/Application Support/Microsoft/Teams"
    safeRemove "${loggedInUserHome}/Library/Application Support/com.microsoft.teams"
    safeRemove "${loggedInUserHome}/Library/Application Support/com.microsoft.teams.helper"

    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.com.microsoft.teams"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.teams2"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.teams2.launcher"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.teams2.notificationcenter"

    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.teams"
    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.teams.helper"
    safeRemove "${loggedInUserHome}/Library/Cookies/com.microsoft.teams.binarycookies"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.teams.binarycookies"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.teams"
    safeRemove "${loggedInUserHome}/Library/Logs/Microsoft Teams"
    safeRemove "${loggedInUserHome}/Library/Logs/Microsoft Teams Helper"
    safeRemove "${loggedInUserHome}/Library/Logs/Microsoft Teams Helper (Renderer)"
    safeRemove "${loggedInUserHome}/Library/Saved Application State/com.microsoft.teams.savedState"
    safeRemove "${loggedInUserHome}/Library/WebKit/com.microsoft.teams"

    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.teams2"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.teams2.launcher"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.teams2.notificationcenter"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.com.microsoft.teams"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.com.microsoft.oneauth"

    safeRemove "/Library/Application Support/TeamsUpdaterDaemon"
    safeRemove "/Library/Application Support/Microsoft/TeamsUpdaterDaemon"
    safeRemove "/Library/Application Support/Teams"

    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.teams.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.teams.plist"
    safeRemove "/Library/Preferences/com.microsoft.teams.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.teams.helper.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.teams.helper.plist"
    safeRemove "/Library/Preferences/com.microsoft.teams.helper.plist"

    safeRemove "${TMPDIR}/com.microsoft.teams"
    safeRemove "${TMPDIR}/com.microsoft.teams Crashes"
    safeRemove "${TMPDIR}/Teams"
    safeRemove "${TMPDIR}/Microsoft Teams Helper (Renderer)"
    safeRemove "${TMPDIR}/v8-compile-cache-501"

    safeRemove "/Library/Logs/Microsoft/Teams"
    if ! runAsUser "${loggedInUser}" /usr/bin/tccutil reset All com.microsoft.teams2 >>"${scriptLog}" 2>&1; then
        warning "Unable to reset Teams TCC state for ${loggedInUser}"
    fi

    ensureLoginKeychainPresent "${loggedInUser}" "${loggedInUserHome}"

    deleteGenericByLabelLoop 'Microsoft Teams Identities Cache' "${loggedInUser}"
    deleteGenericByLabel 'Teams Safe Storage' "${loggedInUser}"
    deleteGenericByLabel 'Microsoft Teams (work or school) Safe Storage' "${loggedInUser}"
    deleteGenericByLabel 'teamsIv' "${loggedInUser}"
    deleteGenericByLabel 'teamsKey' "${loggedInUser}"
    deleteGenericByLabel 'com.microsoft.teams.HockeySDK' "${loggedInUser}"
    deleteGenericByLabel 'com.microsoft.teams.helper.HockeySDK' "${loggedInUser}"

    if [[ -d "${modernBackgroundsStaging}" ]]; then
        /bin/mkdir -p "$(dirname "${modernBackgroundsPath}")" >>"${scriptLog}" 2>&1
        /bin/mv "${modernBackgroundsStaging}" "${modernBackgroundsPath}" >>"${scriptLog}" 2>&1
        /usr/sbin/chown -R "${loggedInUser}" "$(dirname "${modernBackgroundsPath}")" >>"${scriptLog}" 2>&1
    fi

    if [[ -d "${teamsAppPath}" ]]; then
        /usr/bin/codesign -vv --deep "${teamsAppPath}" >>"${scriptLog}" 2>&1
        if [[ $? -ne 0 ]]; then
            warning "Microsoft Teams app bundle damaged; reinstalling"
            safeRemove "${teamsAppPath}"
            shouldInstallTeams="true"
        else
            info "Microsoft Teams codesign verification passed"
        fi
    fi

    while [[ "${shouldInstallTeams}" == "true" && ! -d "${teamsAppPath}" && ${installAttempt} -le ${installationRetries} ]]; do
        info "Installing Microsoft Teams (attempt ${installAttempt}/${installationRetries})"
        repairFromMicrosoftPkg "Microsoft Teams" "${teamsPkgURL}" "" || return 1
        /usr/bin/codesign -vv --deep "${teamsAppPath}" >>"${scriptLog}" 2>&1
        if [[ $? -eq 0 ]]; then
            local installedTeamsVersion
            installedTeamsVersion="$(defaults read "${teamsAppPath}/Contents/Info.plist" CFBundleVersion 2>/dev/null)"
            info "Microsoft Teams installed successfully at version ${installedTeamsVersion}"
            break
        fi
        warning "Microsoft Teams app bundle failed codesign after install attempt ${installAttempt}; removing and retrying"
        safeRemove "${teamsAppPath}"
        ((installAttempt++))
    done

    if [[ "${shouldInstallTeams}" == "true" && ! -d "${teamsAppPath}" ]]; then
        errorOut "Unable to install a valid Microsoft Teams app bundle"
        return 1
    fi

    if [[ "${operationMode}" != "silent" ]]; then
        runAsUser "${loggedInUser}" /usr/bin/open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture" >>"${scriptLog}" 2>&1 || warning "Unable to open Screen Recording settings for Microsoft Teams"
    fi

    return 0
}

function op_reset_teams() {
    info "Starting operation: reset_teams"
    resetTeamsOperation "false" || return 1
    return 0
}

function op_reset_teams_force() {
    info "Starting operation: reset_teams_force"
    resetTeamsOperation "true" || return 1
    return 0
}

function op_reset_autoupdate() {
    info "Starting operation: reset_autoupdate"
    local mauAppPath="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app"

    pkill -9 'Microsoft AutoUpdate' 2>/dev/null
    pkill -9 'Microsoft Update Assistant' 2>/dev/null
    pkill -9 'Microsoft AU Daemon' 2>/dev/null
    pkill -9 'Microsoft AU Bootstrapper' 2>/dev/null
    pkill -9 'com.microsoft.autoupdate.helper' 2>/dev/null
    pkill -9 'com.microsoft.autoupdate.helpertool' 2>/dev/null
    pkill -9 'com.microsoft.autoupdate.bootstrapper.helper' 2>/dev/null

    launchctl stop /Library/LaunchAgents/com.microsoft.update.agent.plist 2>/dev/null
    launchctl stop /Library/LaunchAgents/com.microsoft.autoupdate.helper.plist 2>/dev/null
    launchctl stop /Library/LaunchDaemons/com.microsoft.autoupdate.helper 2>/dev/null
    launchctl stop /Library/LaunchDaemons/com.microsoft.autoupdate.helper.plist 2>/dev/null

    launchctl unload /Library/LaunchAgents/com.microsoft.update.agent.plist 2>/dev/null
    launchctl unload /Library/LaunchAgents/com.microsoft.autoupdate.helper.plist 2>/dev/null
    launchctl unload /Library/LaunchDaemons/com.microsoft.autoupdate.helper 2>/dev/null
    launchctl unload /Library/LaunchDaemons/com.microsoft.autoupdate.helper.plist 2>/dev/null

    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.autoupdate2.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.autoupdate.fba.plist"

    safeRemove "/Library/Preferences/com.microsoft.autoupdate2.plist"
    safeRemove "/Library/Preferences/com.microsoft.autoupdate.fba.plist"

    safeRemove "/var/root/Library/Preferences/com.microsoft.autoupdate2.plist"
    safeRemove "/var/root/Library/Preferences/com.microsoft.autoupdate.fba.plist"

    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.autoupdate2"
    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.autoupdate.fba"

    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.autoupdate2"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.autoupdate2.binarycookies"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.autoupdate.fba"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.autoupdate.fba.binarycookies"

    safeRemove "${loggedInUserHome}/Library/Application Support/Microsoft AU Daemon"

    safeRemove "/Library/Application Support/Microsoft/MERP2.0"

    safeRemove "${TMPDIR}/MSauClones"
    safeRemove "/Library/Caches/com.microsoft.autoupdate.helper"
    safeRemove "/Library/Caches/com.microsoft.autoupdate.fba"
    safeRemove "${TMPDIR}/TelemetryUploadFilecom.microsoft.autoupdate.fba.txt"
    safeRemove "${TMPDIR}/TelemetryUploadFilecom.microsoft.autoupdate2.txt"

    safeRemove "/Applications/.Microsoft Word.app.installBackup"
    safeRemove "/Applications/.Microsoft Excel.app.installBackup"
    safeRemove "/Applications/.Microsoft PowerPoint.app.installBackup"
    safeRemove "/Applications/.Microsoft Outlook.app.installBackup"
    safeRemove "/Applications/.Microsoft OneNote.app.installBackup"

    safeRemove "/Library/Logs/Microsoft/autoupdate.log"

    defaults write /Library/Preferences/com.microsoft.autoupdate2 AcknowledgedDataCollectionPolicy -string 'RequiredDataOnly' >>"${scriptLog}" 2>&1

    if [[ -d "${mauAppPath}" ]]; then
        local mauVersion
        mauVersion="$(defaults read "${mauAppPath}/Contents/Info.plist" CFBundleVersion 2>/dev/null)"
        if ! is-at-least 4.49 "${mauVersion}"; then
            info "Microsoft AutoUpdate is below MOFA minimum; repairing"
            repairFromMicrosoftPkg "Microsoft AutoUpdate" "https://go.microsoft.com/fwlink/?linkid=830196" "" || return 1
        fi
        /usr/bin/codesign -vv --deep "${mauAppPath}" >>"${scriptLog}" 2>&1
        if [[ $? -ne 0 ]]; then
            warning "Microsoft AutoUpdate app bundle damaged; reinstalling"
            safeRemove "${mauAppPath}"
            repairFromMicrosoftPkg "Microsoft AutoUpdate" "https://go.microsoft.com/fwlink/?linkid=830196" "" || return 1
        fi
    fi

    defaults write /Library/Preferences/com.microsoft.autoupdate2 ApplicationsSystem -dict-add "${mauAppPath}" "{ 'Application ID' = 'MSau04'; LCID = 1033 ; 'App Domain' = 'com.microsoft.office' ; }" >>"${scriptLog}" 2>&1

    registerMAUApplicationIfPresent "/Applications/Microsoft Word.app" "MSWD2019" "MSWD15"
    registerMAUApplicationIfPresent "/Applications/Microsoft Excel.app" "XCEL2019" "XCEL15"
    registerMAUApplicationIfPresent "/Applications/Microsoft PowerPoint.app" "PPT32019" "PPT315"
    registerMAUApplicationIfPresent "/Applications/Microsoft Outlook.app" "OPIM2019" "OPIM15"
    registerMAUApplicationIfPresent "/Applications/Microsoft OneNote.app" "ONMC2019" "ONMC15"

    registerMAUStaticApplicationIfPresent "/Applications/OneDrive.app" "{ 'Application ID' = 'ONDR18'; LCID = 1033 ; 'App Domain' = 'com.microsoft.office' ; }"
    registerMAUStaticApplicationIfPresent "/Applications/Microsoft Teams.app" "{ 'Application ID' = 'TEAMS21'; LCID = 1033 ; 'App Domain' = 'com.microsoft.office' ; }"
    registerMAUStaticApplicationIfPresent "/Applications/Microsoft Teams classic.app" "{ 'Application ID' = 'TEAMS10'; LCID = 1033 ; }"
    registerMAUStaticApplicationIfPresent "/Applications/Microsoft Edge.app" "{ 'Application ID' = 'EDGE01'; LCID = 1033 ; }"
    registerMAUStaticApplicationIfPresent "/Applications/Microsoft Edge Beta.app" "{ 'Application ID' = 'EDBT01'; LCID = 1033 ; }"
    registerMAUStaticApplicationIfPresent "/Applications/Microsoft Edge Canary.app" "{ 'Application ID' = 'EDCN01'; LCID = 1033 ; }"
    registerMAUStaticApplicationIfPresent "/Applications/Microsoft Edge Dev.app" "{ 'Application ID' = 'EDDV01'; LCID = 1033 ; }"
    registerMAUStaticApplicationIfPresent "/Applications/Microsoft Remote Desktop.app" "{ 'Application ID' = 'MSRD10'; LCID = 1033 ; }"
    registerMAUStaticApplicationIfPresent "/Applications/Skype For Business.app" "{ 'Application ID' = 'MSFB16'; LCID = 1033 ; }"
    registerMAUStaticApplicationIfPresent "/Applications/Company Portal.app" "{ 'Application ID' = 'IMCP01'; LCID = 1033 ; }"
    registerMAUStaticApplicationIfPresent "/Applications/Microsoft Defender.app" "{ 'Application ID' = 'WDAV00'; LCID = 1033 ; }"
    registerMAUStaticApplicationIfPresent "/Applications/Microsoft Defender ATP.app" "{ 'Application ID' = 'WDAV00'; LCID = 1033 ; }"

    return 0
}

function resetOfficeLicenseCore() {
    pkill -HUP 'Microsoft Word' 2>/dev/null
    pkill -HUP 'Microsoft Excel' 2>/dev/null
    pkill -HUP 'Microsoft PowerPoint' 2>/dev/null
    pkill -HUP 'Microsoft Outlook' 2>/dev/null
    pkill -HUP 'Microsoft OneNote' 2>/dev/null

    ensureLoginKeychainPresent "${loggedInUser}" "${loggedInUserHome}"

    deleteGenericByService 'OneAuthAccount' "${loggedInUser}"
    deleteInternetByService 'msoCredentialSchemeADAL' "${loggedInUser}"
    deleteInternetByService 'msoCredentialSchemeLiveId' "${loggedInUser}"

    deleteGenericByCreatorLoop 'MSOpenTech.ADAL.1' "${loggedInUser}"

    deleteGenericByLabel 'Microsoft Office Identities Cache 2' "${loggedInUser}"
    deleteGenericByLabel 'Microsoft Office Identities Cache 3' "${loggedInUser}"
    deleteGenericByLabel 'Microsoft Office Identities Settings 2' "${loggedInUser}"
    deleteGenericByLabel 'Microsoft Office Identities Settings 3' "${loggedInUser}"
    deleteGenericByLabel 'Microsoft Office Ticket Cache' "${loggedInUser}"
    deleteGenericByLabel 'com.microsoft.adalcache' "${loggedInUser}"

    deleteGenericByCreatorLoop 'Microsoft Office Data' "${loggedInUser}"

    deleteGenericByLabel 'com.microsoft.OutlookCore.Secret' "${loggedInUser}"

    deleteGenericByLabelLoop 'com.helpshift.data_com.microsoft.Outlook' "${loggedInUser}"
    deleteGenericByLabelLoop 'MicrosoftOfficeRMSCredential' "${loggedInUser}"
    deleteGenericByLabelLoop 'MSProtection.framework.service' "${loggedInUser}"
    deleteGenericByLabelLoop 'Exchange' "${loggedInUser}"

    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/mip_policy"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/DRM_Evo.plist"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.com.microsoft.oneauth"

    safeRemove "/Library/Preferences/com.microsoft.office.licensingV2.plist.bak"
    if [[ -f "/Library/Preferences/com.microsoft.office.licensingV2.plist" ]]; then
        mv "/Library/Preferences/com.microsoft.office.licensingV2.plist" "/Library/Preferences/com.microsoft.office.licensingV2.backup" >>"${scriptLog}" 2>&1
    fi

    safeRemove "/Library/Application Support/Microsoft/Office365/com.microsoft.Office365.plist"
    safeRemove "/Library/Application Support/Microsoft/Office365/com.microsoft.Office365V2.plist"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/com.microsoft.Office365.plist"
    if [[ -f "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/com.microsoft.Office365V2.plist" ]]; then
        mv "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/com.microsoft.Office365V2.plist" "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/com.microsoft.Office365V2.backup" >>"${scriptLog}" 2>&1
    fi

    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/com.microsoft.e0E2OUQxNUY1LTAxOUQtNDQwNS04QkJELTAxQTI5M0JBOTk4O.plist"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/e0E2OUQxNUY1LTAxOUQtNDQwNS04QkJELTAxQTI5M0JBOTk4O"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/com.microsoft.O4kTOBJ0M5ITQxATLEJkQ40SNwQDNtQUOxATL1YUNxQUO2E0e.plist"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/O4kTOBJ0M5ITQxATLEJkQ40SNwQDNtQUOxATL1YUNxQUO2E0e"

    safeRemove "/Library/Microsoft/Office/Licenses"
    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/Licenses"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.RMS-XPCService"
    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.Office365ServiceV2"

    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.Word/Data/Library/Application Support/Microsoft"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.Excel/Data/Library/Application Support/Microsoft"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.Powerpoint/Data/Library/Application Support/Microsoft"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.Outlook/Data/Library/Application Support/Microsoft"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.onenote.mac/Data/Library/Application Support/Microsoft"

    if [[ -e "${loggedInUserHome}/Library/Preferences/com.microsoft.office.plist" ]]; then
        runAsUser "${loggedInUser}" defaults delete "${loggedInUserHome}/Library/Preferences/com.microsoft.office" OfficeActivationEmailAddress >>"${scriptLog}" 2>&1
        runAsUser "${loggedInUser}" defaults write "${loggedInUserHome}/Library/Preferences/com.microsoft.office" OfficeAutoSignIn -bool TRUE >>"${scriptLog}" 2>&1
        runAsUser "${loggedInUser}" defaults write "${loggedInUserHome}/Library/Preferences/com.microsoft.office" HasUserSeenFREDialog -bool TRUE >>"${scriptLog}" 2>&1
        runAsUser "${loggedInUser}" defaults write "${loggedInUserHome}/Library/Preferences/com.microsoft.office" HasUserSeenEnterpriseFREDialog -bool TRUE >>"${scriptLog}" 2>&1
    fi

    [[ -d "${loggedInUserHome}/Library/Containers/com.microsoft.Word/Data/Library/Preferences" ]] && runAsUser "${loggedInUser}" defaults write "${loggedInUserHome}/Library/Containers/com.microsoft.Word/Data/Library/Preferences/com.microsoft.Word" kSubUIAppCompletedFirstRunSetup1507 -bool FALSE >>"${scriptLog}" 2>&1
    [[ -d "${loggedInUserHome}/Library/Containers/com.microsoft.Excel/Data/Library/Preferences" ]] && runAsUser "${loggedInUser}" defaults write "${loggedInUserHome}/Library/Containers/com.microsoft.Excel/Data/Library/Preferences/com.microsoft.Excel" kSubUIAppCompletedFirstRunSetup1507 -bool FALSE >>"${scriptLog}" 2>&1
    [[ -d "${loggedInUserHome}/Library/Containers/com.microsoft.Powerpoint/Data/Library/Preferences" ]] && runAsUser "${loggedInUser}" defaults write "${loggedInUserHome}/Library/Containers/com.microsoft.Powerpoint/Data/Library/Preferences/com.microsoft.Powerpoint" kSubUIAppCompletedFirstRunSetup1507 -bool FALSE >>"${scriptLog}" 2>&1
    [[ -d "${loggedInUserHome}/Library/Containers/com.microsoft.Outlook/Data/Library/Preferences" ]] && runAsUser "${loggedInUser}" defaults write "${loggedInUserHome}/Library/Containers/com.microsoft.Outlook/Data/Library/Preferences/com.microsoft.Outlook" kSubUIAppCompletedFirstRunSetup1507 -bool FALSE >>"${scriptLog}" 2>&1
    [[ -d "${loggedInUserHome}/Library/Containers/com.microsoft.onenote.mac/Data/Library/Preferences" ]] && runAsUser "${loggedInUser}" defaults write "${loggedInUserHome}/Library/Containers/com.microsoft.onenote.mac/Data/Library/Preferences/com.microsoft.onenote.mac" kSubUIAppCompletedFirstRunSetup1507 -bool FALSE >>"${scriptLog}" 2>&1

    safeRemove "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/MicrosoftRegistrationDB.reg"
    return 0
}

function resetOfficeExtendedSignInArtifacts() {
    deleteGenericByLabel 'Microsoft Office Ticket Cache 2' "${loggedInUser}"

    deleteGenericByLabelLoop 'Microsoft Teams Identities Cache' "${loggedInUser}"
    deleteGenericByLabel 'Teams Safe Storage' "${loggedInUser}"
    deleteGenericByLabel 'Microsoft Teams (work or school) Safe Storage' "${loggedInUser}"
    deleteGenericByLabel 'teamsIv' "${loggedInUser}"
    deleteGenericByLabel 'teamsKey' "${loggedInUser}"
    deleteGenericByLabel 'com.microsoft.teams.HockeySDK' "${loggedInUser}"
    deleteGenericByLabel 'com.microsoft.teams.helper.HockeySDK' "${loggedInUser}"

    deleteGenericByLabel 'com.microsoft.OneDrive.FinderSync.HockeySDK' "${loggedInUser}"
    deleteGenericByLabel 'com.microsoft.OneDrive.HockeySDK' "${loggedInUser}"
    deleteGenericByLabel 'com.microsoft.OneDriveUpdater.HockeySDK' "${loggedInUser}"
    deleteGenericByLabel 'com.microsoft.OneDriveStandaloneUpdater.HockeySDK' "${loggedInUser}"
    deleteGenericByLabel 'OneDrive Standalone Cached Credential Business - Business1' "${loggedInUser}"
    deleteGenericByLabel 'OneDrive Standalone Cached Credential' "${loggedInUser}"
    deleteGenericByService 'com.microsoft.onedrive.cookies' "${loggedInUser}"

    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.msa-login-hint.plist"

    local keychainDB
    keychainDB="$(findKeychainDB "${loggedInUserHome}")"
    if [[ -n "${keychainDB}" ]]; then
        /usr/bin/sqlite3 "${keychainDB}" "DELETE FROM genp WHERE agrp='UBF8T346G9.com.microsoft.identity.universalstorage';" >>"${scriptLog}" 2>&1
    fi

    safeRemove "${loggedInUserHome}/Library/Keychains/Microsoft_Entity_Certificates-db"
    return 0
}

function finalizeOfficeCredentialReset() {
    /usr/bin/killall cfprefsd >>"${scriptLog}" 2>&1
    return 0
}

function op_reset_license() {
    info "Starting operation: reset_license"
    resetOfficeLicenseCore || return 1
    finalizeOfficeCredentialReset || return 1
    return 0
}

function op_reset_credentials() {
    info "Starting operation: reset_credentials"
    resetOfficeLicenseCore || return 1
    resetOfficeExtendedSignInArtifacts || return 1
    finalizeOfficeCredentialReset || return 1
    return 0
}

function op_remove_office() {
    info "Starting operation: remove_office"
    removeOfficePostinstall || return 1
    return 0
}

function op_remove_skypeforbusiness() {
    info "Starting operation: remove_skypeforbusiness"

    pkill -9 'Skype for Business' 2>/dev/null

    safeRemove "${loggedInUserHome}/Library/Application Scripts/com.microsoft.SkypeForBusiness"
    safeRemove "${loggedInUserHome}/Library/Containers/com.microsoft.SkypeForBusiness"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.OutlookSkypeIntegration.plist"

    safeRemove "/Library/Preferences/com.microsoft.SkypeForBusiness.plist"
    safeRemove "/Library/Managed Preferences/com.microsoft.SkypeForBusiness.plist"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.microsoft.SkypeForBusiness.plist"

    ensureLoginKeychainPresent "${loggedInUser}" "${loggedInUserHome}"

    deleteGenericByLabel 'com.microsoft.SkypeForBusiness.HockeySDK' "${loggedInUser}"
    deleteGenericByLabel 'Skype for Business' "${loggedInUser}"

    safeRemove "/Applications/Skype for Business.app"

    /usr/sbin/pkgutil --forget com.microsoft.package.Microsoft_AU_Bootstrapper.app >>"${scriptLog}" 2>&1
    /usr/sbin/pkgutil --forget com.microsoft.SkypeForBusiness >>"${scriptLog}" 2>&1

    return 0
}

function op_remove_defender() {
    info "Starting operation: remove_defender"

    pkill -9 'Microsoft Defender*' 2>/dev/null

    if [[ -e "/Applications/Microsoft Defender.app/Contents/Resources/Tools/uninstall/uninstall" ]]; then
        /Applications/Microsoft\ Defender.app/Contents/Resources/Tools/uninstall/uninstall >>"${scriptLog}" 2>&1
    else
        safeRemove "/Applications/Microsoft Defender.app"
    fi

    safeRemove "${loggedInUserHome}/Library/Application Scripts/UBF8T346G9.com.microsoft.wdav"
    safeRemove "${loggedInUserHome}/Library/Application Support/com.microsoft.wdav.tray"
    safeRemove "${loggedInUserHome}/Library/Application Support/com.microsoft.wdav.mainux"
    safeRemove "${loggedInUserHome}/Library/Application Support/com.microsoft.wdav.shim"
    safeRemove "${loggedInUserHome}/Library/Application Support/Microsoft Defender Helper"

    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.wdav.tray"
    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.wdav.mainux"
    safeRemove "${loggedInUserHome}/Library/Caches/com.microsoft.wdav.shim"

    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.wdav.tray"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.wdav.mainux"
    safeRemove "${loggedInUserHome}/Library/HTTPStorages/com.microsoft.wdav.shim"

    safeRemove "${loggedInUserHome}/Library/Logs/Microsoft/Defender"
    safeRemove "${loggedInUserHome}/Library/Preferences/UBF8T346G9.com.microsoft.wdav.plist"

    /usr/sbin/pkgutil --forget com.microsoft.dlp.ux >>"${scriptLog}" 2>&1
    /usr/sbin/pkgutil --forget com.microsoft.dlp.daemon >>"${scriptLog}" 2>&1
    /usr/sbin/pkgutil --forget com.microsoft.dlp.agent >>"${scriptLog}" 2>&1

    return 0
}

function op_remove_acrobat_addin() {
    info "Starting operation: remove_acrobat_addin"

    prepareForAcrobatAddinRemoval

    local addinPaths=(
    )
    local baseDirectories=(
        "/Library/Application Support/Microsoft/Office365/User Content.localized"
        "${loggedInUserHome}/Library/Group Containers/UBF8T346G9.Office/User Content.localized"
    )
    local startupDirectoryNames=(Startup Startup.localized)
    local powerPointDirectoryNames=(Powerpoint PowerPoint)
    local baseDirectory
    local startupDirectory
    local powerPointDirectory

    for baseDirectory in "${baseDirectories[@]}"; do
        for startupDirectory in "${startupDirectoryNames[@]}"; do
            addinPaths+=("${baseDirectory}/${startupDirectory}/Excel/AcrobatExcelAddin.xlam")
            addinPaths+=("${baseDirectory}/${startupDirectory}/Word/linkCreation.dotm")
            for powerPointDirectory in "${powerPointDirectoryNames[@]}"; do
                addinPaths+=("${baseDirectory}/${startupDirectory}/${powerPointDirectory}/SaveAsAdobePDF.ppam")
            done
        done
    done

    local targetPath
    for targetPath in "${addinPaths[@]}"; do
        safeRemove "${targetPath}"
    done

    return 0
}

function op_remove_zoomplugin() {
    info "Starting operation: remove_zoomplugin"

    /Applications/ZoomOutlookPlugin/Uninstall/Contents/MacOS/Uninstall >>"${scriptLog}" 2>&1

    launchctl stop /Library/LaunchAgents/us.zoom.pluginagent.plist 2>/dev/null
    launchctl unload /Library/LaunchAgents/us.zoom.pluginagent.plist 2>/dev/null
    launchctl stop "${loggedInUserHome}/Library/LaunchAgents/us.zoom.pluginagent.plist" 2>/dev/null
    launchctl unload "${loggedInUserHome}/Library/LaunchAgents/us.zoom.pluginagent.plist" 2>/dev/null

    safeRemove "/Library/LaunchAgents/us.zoom.pluginagent.plist"
    safeRemove "${loggedInUserHome}/Library/LaunchAgents/us.zoom.pluginagent.plist"
    safeRemove "${loggedInUserHome}/Library/Logs/zoomoutlookplugin.log"
    safeRemove "${loggedInUserHome}/Library/Preferences/ZoomChat.plist"

    safeRemove "/Library/Application Support/ZoomOutlookPlugin"
    safeRemove "/Library/Application Support/Microsoft/ZoomOutlookPlugin"
    safeRemove "/Library/ScriptingAdditions/zOLPluginInjection.osax"
    safeRemove "/Users/Shared/ZoomOutlookPlugin"

    safeRemove "/Applications/ZoomOutlookPlugin"

    /usr/sbin/pkgutil --forget ZoomMacOutlookPlugin.pkg >>"${scriptLog}" 2>&1

    return 0
}

function op_remove_webexpt() {
    info "Starting operation: remove_webexpt"

    /Applications/WebEx\ Productivity\ Tools/Uninstall/Contents/MacOS/Uninstall >>"${scriptLog}" 2>&1

    launchctl stop /Library/LaunchAgents/com.webex.pluginagent.plist 2>/dev/null
    launchctl unload /Library/LaunchAgents/com.webex.pluginagent.plist 2>/dev/null

    safeRemove "${loggedInUserHome}/Library/Application Support/Cisco/Webex Plugin"
    safeRemove "${loggedInUserHome}/Library/Application Support/Cisco/Webex Meetings"
    safeRemove "${loggedInUserHome}/Library/Caches/com.cisco.webex.pluginservice"
    safeRemove "${loggedInUserHome}/Library/Caches/com.cisco.webex.webexmta"
    safeRemove "${loggedInUserHome}/Library/Group Containers/group.com.cisco.webex.meetings"
    safeRemove "${loggedInUserHome}/Library/Logs/PT"
    safeRemove "${loggedInUserHome}/Library/Logs/webexmta"
    safeRemove "${loggedInUserHome}/Library/Preferences/com.cisco.webex.pluginservice.plist"

    safeRemove "/Library/Application Support/Microsoft/WebExPlugin"
    safeRemove "/Library/ScriptingAdditions/WebexScriptAddition.osax"
    safeRemove "/Users/Shared/WebExPlugin"

    safeRemove "/Applications/WebEx Productivity Tools"

    /usr/sbin/pkgutil --forget olp.mac.webex.com >>"${scriptLog}" 2>&1

    return 0
}


####################################################################################################
#
# Dispatcher and Execution
#
####################################################################################################

function runOperation() {
    local opID="$1"
    case "${opID}" in
        reset_factory) op_reset_factory ;;
        reset_word) op_reset_word ;;
        reset_excel) op_reset_excel ;;
        reset_powerpoint) op_reset_powerpoint ;;
        reset_outlook) op_reset_outlook ;;
        remove_outlook_data) op_remove_outlook_data ;;
        reset_onenote) op_reset_onenote ;;
        remove_onenote_data) op_remove_onenote_data ;;
        reset_onedrive) op_reset_onedrive ;;
        reset_teams) op_reset_teams ;;
        reset_teams_force) op_reset_teams_force ;;
        reset_autoupdate) op_reset_autoupdate ;;
        reset_license) op_reset_license ;;
        reset_credentials) op_reset_credentials ;;
        remove_office) op_remove_office ;;
        remove_skypeforbusiness) op_remove_skypeforbusiness ;;
        remove_defender) op_remove_defender ;;
        remove_acrobat_addin) op_remove_acrobat_addin ;;
        remove_zoomplugin) op_remove_zoomplugin ;;
        remove_webexpt) op_remove_webexpt ;;
        *)
            errorOut "Unknown operation ID: ${opID}"
            return 1
            ;;
    esac
}

function sortOperationsByExecutionPhase() {
    local sorted=()
    local op

    # reset operations
    for op in reset_factory reset_word reset_excel reset_powerpoint reset_outlook reset_onenote reset_onedrive reset_teams reset_teams_force reset_autoupdate reset_license reset_credentials; do
        isOperationSelected "${op}" && sorted+=("${op}")
    done

    # data-removal operations
    for op in remove_outlook_data remove_onenote_data; do
        isOperationSelected "${op}" && sorted+=("${op}")
    done

    # ancillary removals
    for op in remove_defender remove_acrobat_addin remove_zoomplugin remove_webexpt remove_skypeforbusiness; do
        isOperationSelected "${op}" && sorted+=("${op}")
    done

    # full office removal last
    isOperationSelected remove_office && sorted+=(remove_office)

    resolvedOperations=("${sorted[@]}")
}

function preflightChecks() {
    [[ -f "${scriptLog}" ]] || touch "${scriptLog}" || fatal "Unable to create log file ${scriptLog}"

    preFlight "\n\n###\n# ${humanReadableScriptName} (${scriptVersion})\n# https://snelson.us\n#\n# Operation Mode: ${operationMode}\n####\n\n"
    preFlight "Initiating ..."

    if [[ $(id -u) -ne 0 ]]; then
        fatal "This script must run as root"
    fi

    loggedInUser="$(getLoggedInUser)"
    if [[ -z "${loggedInUser}" ]]; then
        fatal "No non-root console user detected; refusing to run user-scoped operations"
    fi

    loggedInUserFullname="$(id -F "${loggedInUser}" 2>/dev/null)"
    loggedInUserID="$(id -u "${loggedInUser}" 2>/dev/null)"
    loggedInUserHomeDirectory="$(dscl . read "/Users/${loggedInUser}" NFSHomeDirectory 2>/dev/null | awk -F ' ' '{print $2}')"
    if [[ -z "${loggedInUserHomeDirectory}" ]]; then
        loggedInUserHomeDirectory="$(setHomeFolder "${loggedInUser}")"
    fi
    if [[ -z "${loggedInUserHomeDirectory}" || "${loggedInUserHomeDirectory}" == "/var/root" ]]; then
        fatal "Resolved unsafe home directory for user '${loggedInUser}': ${loggedInUserHomeDirectory}"
    fi
    loggedInUserHome="${loggedInUserHomeDirectory}"

    preFlight "Running as root; user: ${loggedInUserFullname} (${loggedInUser}) [${loggedInUserID}]; home: ${loggedInUserHome}"

    if [[ "${operationMode}" != "silent" ]]; then
        dialogCheck
    fi
}

function validateSelectedOperations() {
    if [[ ${#selectedOperations[@]} -eq 0 ]]; then
        warning "No operations selected"
        if [[ "${operationMode}" == "silent" ]]; then
            exit 2
        fi
        return 0
    fi

    local op
    for op in "${selectedOperations[@]}"; do
        if [[ -z "${operationTitle[${op}]}" ]]; then
            fatal "Invalid operation ID requested: ${op}"
        fi
    done
}

function main() {
    preflightChecks

    showIntroDialog
    showSelectionDialog
    validateSelectedOperations
    resolveDependencies
    sortOperationsByExecutionPhase
    confirmDestructiveSelection

    info "Resolved operations: ${resolvedOperations[*]}"

    startProgressDialog

    local total="${#resolvedOperations[@]}"
    local index=0

    if isOperationSelected remove_office; then
        ((total++))
        ((index++))
        updateProgressDialog "${index}" "${total}" "Running remove_office preinstall (${index}/${total})"

        info "Executing remove_office preinstall phase"
        if ! removeOfficePreinstall; then
            appendFailure remove_office
            errorOut "remove_office preinstall phase failed"

            writeDialogCommand "progresstext: remove_office preinstall failed | Elapsed Time: $(formattedElapsedTime)"
            writeDialogCommand "button1text: Close"
            writeDialogCommand "button1: enable"
            sleep 1
            writeDialogCommand "quit:"
            waitForProgressDialog

            showCompletionDialog
            exit 20
        fi

        updateCompletedProgressDialog "${index}" "${total}" "Completed remove_office preinstall (${index}/${total})"
    fi

    local op
    for op in "${resolvedOperations[@]}"; do
        ((index++))
        updateProgressDialog "${index}" "${total}" "Running ${op} (${index}/${total})"

        if runOperation "${op}"; then
            appendCompletion "${op}"
            info "Operation succeeded: ${op}"
        else
            appendFailure "${op}"
            errorOut "Operation failed: ${op}"
        fi

        updateCompletedProgressDialog "${index}" "${total}" "Completed ${op} (${index}/${total})"
    done

    finishProgressDialog
    showCompletionDialog
    promptForRestart

    if [[ ${#failedOperations[@]} -gt 0 ]]; then
        exit 20
    fi

    exit 0
}

main "$@"
