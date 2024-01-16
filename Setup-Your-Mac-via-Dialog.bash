#!/bin/bash
# shellcheck disable=SC2001,SC1111,SC1112,SC2143,SC2145,SC2086,SC2089,SC2090

####################################################################################################
#
# Setup Your Mac via swiftDialog
# https://snelson.us/sym
#
####################################################################################################
#
# HISTORY
#
#   Version 1.13.0, 24-Oct-2023, Dan K. Snelson (@dan-snelson)
#   - 🔥 **Breaking Change** for users of Setup Your Mac prior to `1.13.0` 🔥 
#       - Removed `setupYourMacPolicyArrayIconPrefixUrl` (in favor using the fully qualified domain name of the server which hosts your icons)
#   - Added [SYM-Helper] to identify variables which can be configured in SYM-Helper (0.8.0)
#   - Updated sample banner image (Image by pikisuperstar on Freepik)
#   - Added `overlayoverride` variable to dynamically override the `overlayicon`, based on which Configuration is selected by the end-user ([Pull Request No. 111](https://github.com/dan-snelson/Setup-Your-Mac/pull/111); thanks yet again, @drtaru!)
#   - Modified the display of support-related information (including adding `supportTeamWebsite` (Addresses [Issue No. 97](https://github.com/dan-snelson/Setup-Your-Mac/issues/97); thanks, @theahadub!))
#   - Adjustments to Completion Actions (including the `wait` flavor; thanks for the heads-up, @Tom!)
#   - Updated Microsoft Teams filepath validation
#   - Add position prompt (Addresses [Issue No. 120](https://github.com/dan-snelson/Setup-Your-Mac/issues/120); thanks for the suggestion, @astrugatch! [Pull Request No. 121](https://github.com/dan-snelson/Setup-Your-Mac/pull/121); thanks, @drtaru! This has to be your best one yet!)
#   - Corrections to "Continue" button after Network Quality test [Pull Request No. 115](https://github.com/dan-snelson/Setup-Your-Mac/pull/115); thanks, @delize!
#
#   Version 1.13.1, 08-Dec-2023, Dan K. Snelson (@dan-snelson)
#   - Updated Vimeo ID
#   - Corrected omission of [SYM-Helper] for `moveableInProduction`
#   - Updated "Microsoft Office 365" to "Microsoft 365"
#   - Added OS Build number to webhook output [Pull Request No. 124](https://github.com/dan-snelson/Setup-Your-Mac/pull/124); thanks, @drtaru!
#   - Changed filepath validation test from `-f` (i.e., "True if file exists and is a regular file") to `-e` (i.e., "True if file exists (regardless of type)."); thanks for the inspiration, @mrmte! [Issue 19](https://github.com/BIG-RAT/SYM-Helper/issues/19); thanks for the code suggestion, @bartreardon!
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Version and Jamf Pro Script Parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="1.13.1-b3"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
scriptLog="${4:-"/var/log/org.churchofjesuschrist.log"}"                        # Parameter 4: Script Log Location [ /var/log/org.churchofjesuschrist.log ] (i.e., Your organization's default location for client-side logs)
debugMode="${5:-"verbose"}"                                                     # Parameter 5: Debug Mode [ verbose (default) | true | false ]
welcomeDialog="${6:-"userInput"}"                                               # Parameter 6: Welcome dialog [ userInput (default) | video | messageOnly | false ]
completionActionOption="${7:-"Restart Attended"}"                               # Parameter 7: Completion Action [ wait | sleep (with seconds) | Shut Down | Shut Down Attended | Shut Down Confirm | Restart | Restart Attended (default) | Restart Confirm | Log Out | Log Out Attended | Log Out Confirm ]
requiredMinimumBuild="${8:-"disabled"}"                                         # Parameter 8: Required Minimum Build [ disabled (default) | 22E ] (i.e., Your organization's required minimum build of macOS to allow users to proceed; use "22E" for macOS 13.3)
outdatedOsAction="${9:-"/System/Library/CoreServices/Software Update.app"}"     # Parameter 9: Outdated OS Action [ /System/Library/CoreServices/Software Update.app (default) | jamfselfservice://content?entity=policy&id=117&action=view ] (i.e., Jamf Pro Self Service policy ID for operating system ugprades)
webhookURL="${10:-""}"                                                          # Parameter 10: Microsoft Teams or Slack Webhook URL [ Leave blank to disable (default) | https://microsoftTeams.webhook.com/URL | https://hooks.slack.com/services/URL ] Can be used to send a success or failure message to Microsoft Teams or Slack via Webhook. (Function will automatically detect if Webhook URL is for Slack or Teams; can be modified to include other communication tools that support functionality.)
presetConfiguration="${11:-""}"                                                 # Parameter 11: Specify a Configuration (i.e., `policyJSON`; NOTE: If set, `promptForConfiguration` will be automatically suppressed and the preselected configuration will be used instead)
swiftDialogMinimumRequiredVersion="2.3.2.4726"                                  # This will be set and updated as dependancies on newer features change.



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Various Feature Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

debugModeSleepAmount="3"    # Delay for various actions when running in Debug Mode
failureDialog="true"        # Display the so-called "Failure" dialog (after the main SYM dialog) [ true | false ]



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Welcome Message User Input Customization Choices (thanks, @rougegoat!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# [SYM-Helper] These control which user input boxes are added to the first page of Setup Your Mac. If you do not want to ask about a value, set it to any other value
promptForUsername="true"
prefillUsername="true"          # prefills the currently logged in user's username
promptForRealName="true"
prefillRealname="true"          # prefills the currently logged in user's fullname
promptForEmail="true"
promptForComputerName="true"
promptForAssetTag="true"
promptForRoom="true"
promptForBuilding="true"
promptForDepartment="true"
promptForPosition="true"        # When set to true dynamically prompts the user to select from a list of positions or manually enter one at the welcomeDialog, see "positionListRaw" to define the selection / entry type
promptForConfiguration="true"   # Removes the Configuration dropdown entirely and uses the "Catch-all (i.e., used when `welcomeDialog` is set to `video` or `false`)" or presetConfiguration policyJSON

# Set to "true" to suppress the Update Inventory option on policies that are called
suppressReconOnPolicy="false"

# [SYM-Helper] Disables the Blurscreen enabled by default in Production
moveableInProduction="false"

# [SYM-Helper] An unsorted, comma-separated list of buildings (with possible duplication). If empty, this will be hidden from the user info prompt
buildingsListRaw="Benson (Ezra Taft) Building,Brimhall (George H.) Building,BYU Conference Center,Centennial Carillon Tower,Chemicals Management Building,Clark (Herald R.) Building,Clark (J. Reuben) Building,Clyde (W.W.) Engineering Building,Crabtree (Roland A.) Technology Building,Ellsworth (Leo B.) Building,Engineering Building,Eyring (Carl F.) Science Center,Grant (Heber J.) Building,Harman (Caroline Hemenway) Building,Harris (Franklin S.) Fine Arts Center,Johnson (Doran) House East,Kimball (Spencer W.) Tower,Knight (Jesse) Building,Lee (Harold B.) Library,Life Sciences Building,Life Sciences Greenhouses,Maeser (Karl G.) Building,Martin (Thomas L.) Building,McKay (David O.) Building,Nicholes (Joseph K.) Building,Smith (Joseph F.) Building,Smith (Joseph) Building,Snell (William H.) Building,Talmage (James E.) Math Sciences/Computer Building,Tanner (N. Eldon) Building,Taylor (John) Building,Wells (Daniel H.) Building"

# A sorted, unique, JSON-compatible list of buildings
buildingsList=$( echo "${buildingsListRaw}" | tr ',' '\n' | sort -f | uniq | sed -e 's/^/\"/' -e 's/$/\",/' -e '$ s/.$//' )

# [SYM-Helper] An unsorted, comma-separated list of departments (with possible duplication). If empty, this will be hidden from the user info prompt
departmentListRaw="Asset Management,Sales,Australia Area Office,Purchasing / Sourcing,Board of Directors,Strategic Initiatives & Programs,Operations,Business Development,Marketing,Creative Services,Customer Service / Customer Experience,Risk Management,Engineering,Finance / Accounting,Sales,General Management,Human Resources,Marketing,Investor Relations,Legal,Marketing,Sales,Product Management,Production,Corporate Communications,Information Technology / Technology,Quality Assurance,Project Management Office,Sales,Technology"

# A sorted, unique, JSON-compatible list of departments
departmentList=$( echo "${departmentListRaw}" | tr ',' '\n' | sort -f | uniq | sed -e 's/^/\"/' -e 's/$/\",/' -e '$ s/.$//' )

# An unsorted, comma-separated list of departments (with possible duplication). If empty and promptForPosition is "true" a user-input box will be shown instead of a dropdown
positionListRaw="Developer,Management,Sales,Marketing"

# A sorted, unique, JSON-compatible list of positions
positionList=$( echo "${positionListRaw}" | tr ',' '\n' | sort -f | uniq | sed -e 's/^/\"/' -e 's/$/\",/' -e '$ s/.$//' )

# [SYM-Helper] Branding overrides
brandingBanner="https://img.freepik.com/free-vector/green-abstract-geometric-wallpaper_52683-29623.jpg" # Image by pikisuperstar on Freepik
brandingBannerDisplayText="true"
brandingIconLight="https://cdn-icons-png.flaticon.com/512/979/979585.png"
brandingIconDark="https://cdn-icons-png.flaticon.com/512/740/740878.png"

# [SYM-Helper] IT Support Variables - Use these if the default text is fine but you want your org's info inserted instead
supportTeamName="Support Team Name"
supportTeamPhone="+1 (801) 555-1212"
supportTeamEmail="support@domain.com"
supportTeamWebsite="support.domain.com"
supportTeamHyperlink="[${supportTeamWebsite}](https://${supportTeamWebsite})"
supportKB="KB8675309"
supportTeamErrorKB="[${supportKB}](https://servicenow.company.com/support?id=kb_article_view&sysparm_article=${supportKB}#Failures)"

# Disable the "Continue" button in the User Input "Welcome" dialog until Dynamic Download Estimates have complete [ true | false ] (thanks, @Eltord!)
lockContinueBeforeEstimations="false"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Operating System, Computer Model Name, etc.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

osVersion=$( sw_vers -productVersion )
osVersionExtra=$( sw_vers -productVersionExtra ) 
osBuild=$( sw_vers -buildVersion )
osMajorVersion=$( echo "${osVersion}" | awk -F '.' '{print $1}' )
if [[ -n $osVersionExtra ]] && [[ "${osMajorVersion}" -ge 13 ]]; then osVersion="${osVersion} ${osVersionExtra}"; fi # Report RSR sub version if applicable
modelName=$( /usr/libexec/PlistBuddy -c 'Print :0:_items:0:machine_name' /dev/stdin <<< "$(system_profiler -xml SPHardwareDataType)" )
reconOptions=""
exitCode="0"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Configuration Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

configurationDownloadEstimation="true"      # [ true (default) | false ]
correctionCoefficient="1.01"                # "Fudge factor" (to help estimate match reality)

configurationCatchAllSize="34"              # Catch-all Configuration in Gibibits (i.e., Total File Size in Gigabytes * 7.451)
configurationCatchAllInstallBuffer="0"      # Buffer time added to estimates to include installation time of packages, in seconds. Set to 0 to disable. 

configurationOneName="Required"
configurationOneDescription="Minimum organization apps"
configurationOneSize="34"                   # Configuration One in Gibibits (i.e., Total File Size in Gigabytes * 7.451)
configurationOneInstallBuffer="0"           # Buffer time added to estimates to include installation time of packages, in seconds. Set to 0 to disable. 

configurationTwoName="Recommended"
configurationTwoDescription="Required apps and Microsoft 365"
configurationTwoSize="62"                   # Configuration Two in Gibibits (i.e., Total File Size in Gigabytes * 7.451) 
configurationTwoInstallBuffer="0"           # Buffer time added to estimates to include installation time of packages, in seconds. Set to 0 to disable. 

configurationThreeName="Complete"
configurationThreeDescription="Recommended apps, Adobe Acrobat Reader and Google Chrome"
configurationThreeSize="106"                # Configuration Three in Gibibits (i.e., Total File Size in Gigabytes * 7.451) 
configurationThreeInstallBuffer="0"         # Buffer time added to estimates to include installation time of packages, in seconds. Set to 0 to disable. 



####################################################################################################
#
# Pre-flight Checks
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Script Logging Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Current Logged-in User Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function currentLoggedInUser() {
    loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
    updateScriptLog "PRE-FLIGHT CHECK: Current Logged-in User: ${loggedInUser}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n###\n# Setup Your Mac (${scriptVersion})\n# https://snelson.us/sym\n###\n"
updateScriptLog "PRE-FLIGHT CHECK: Initiating …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running under bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "$BASH" != "/bin/bash" ]] ; then
    updateScriptLog "PRE-FLIGHT CHECK: This script must be run under 'bash', please do not run it using 'sh', 'zsh', etc.; exiting."
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    updateScriptLog "PRE-FLIGHT CHECK: This script must be run as root; exiting."
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Setup Assistant has completed
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

while pgrep -q -x "Setup Assistant"; do
    updateScriptLog "PRE-FLIGHT CHECK: Setup Assistant is still running; pausing for 2 seconds"
    sleep 2
done

updateScriptLog "PRE-FLIGHT CHECK: Setup Assistant is no longer running; proceeding …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm Dock is running / user is at Desktop
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

until pgrep -q -x "Finder" && pgrep -q -x "Dock"; do
    updateScriptLog "PRE-FLIGHT CHECK: Finder & Dock are NOT running; pausing for 1 second"
    sleep 1
done

updateScriptLog "PRE-FLIGHT CHECK: Finder & Dock are running; proceeding …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Logged-in System Accounts
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "PRE-FLIGHT CHECK: Check for Logged-in System Accounts …"
currentLoggedInUser

counter="1"

until { [[ "${loggedInUser}" != "_mbsetupuser" ]] || [[ "${counter}" -gt "180" ]]; } && { [[ "${loggedInUser}" != "loginwindow" ]] || [[ "${counter}" -gt "30" ]]; } ; do

    updateScriptLog "PRE-FLIGHT CHECK: Logged-in User Counter: ${counter}"
    currentLoggedInUser
    sleep 2
    ((counter++))

done

loggedInUserFullname=$( id -F "${loggedInUser}" )
loggedInUserFirstname=$( echo "$loggedInUserFullname" | sed -E 's/^.*, // ; s/([^ ]*).*/\1/' | sed 's/\(.\{25\}\).*/\1…/' | awk '{print ( $0 == toupper($0) ? toupper(substr($0,1,1))substr(tolower($0),2) : toupper(substr($0,1,1))substr($0,2) )}' )
loggedInUserID=$( id -u "${loggedInUser}" )
updateScriptLog "PRE-FLIGHT CHECK: Current Logged-in User First Name: ${loggedInUserFirstname}"
updateScriptLog "PRE-FLIGHT CHECK: Current Logged-in User ID: ${loggedInUserID}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Operating System Version and Build
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${requiredMinimumBuild}" == "disabled" ]]; then

    updateScriptLog "PRE-FLIGHT CHECK: 'requiredMinimumBuild' has been set to ${requiredMinimumBuild}; skipping OS validation."
    updateScriptLog "PRE-FLIGHT CHECK: macOS ${osVersion} (${osBuild}) installed"

else

    # Since swiftDialog requires at least macOS 12 Monterey, first confirm the major OS version
    if [[ "${osMajorVersion}" -ge 12 ]] ; then

        updateScriptLog "PRE-FLIGHT CHECK: macOS ${osMajorVersion} installed; checking build version ..."

        # Confirm the Mac is running `requiredMinimumBuild` (or later)
        if [[ "${osBuild}" > "${requiredMinimumBuild}" ]]; then

            updateScriptLog "PRE-FLIGHT CHECK: macOS ${osVersion} (${osBuild}) installed; proceeding ..."

        # When the current `osBuild` is older than `requiredMinimumBuild`; exit with error
        else
            updateScriptLog "PRE-FLIGHT CHECK: The installed operating system, macOS ${osVersion} (${osBuild}), needs to be updated to Build ${requiredMinimumBuild}; exiting with error."
            osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\rExpected macOS Build '${requiredMinimumBuild}' (or newer), but found macOS '${osVersion}' ('${osBuild}').\r\r" with title "Setup Your Mac: Detected Outdated Operating System" buttons {"Open Software Update"} with icon caution'
            updateScriptLog "PRE-FLIGHT CHECK: Executing /usr/bin/open '${outdatedOsAction}' …"
            su - "${loggedInUser}" -c "/usr/bin/open \"${outdatedOsAction}\""
            exit 1

        fi

    # The Mac is running an operating system older than macOS 12 Monterey; exit with error
    else

        updateScriptLog "PRE-FLIGHT CHECK: swiftDialog requires at least macOS 12 Monterey and this Mac is running ${osVersion} (${osBuild}), exiting with error."
        osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\rExpected macOS Build '${requiredMinimumBuild}' (or newer), but found macOS '${osVersion}' ('${osBuild}').\r\r" with title "Setup Your Mac: Detected Outdated Operating System" buttons {"Open Software Update"} with icon caution'
        updateScriptLog "PRE-FLIGHT CHECK: Executing /usr/bin/open '${outdatedOsAction}' …"
        su - "${loggedInUser}" -c "/usr/bin/open \"${outdatedOsAction}\""
        exit 1

    fi

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Ensure computer does not go to sleep during SYM (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

symPID="$$"
updateScriptLog "PRE-FLIGHT CHECK: Caffeinating this script (PID: $symPID)"
caffeinate -dimsu -w $symPID &



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Toggle `jamf` binary check-in (thanks, @robjschroeder!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function toggleJamfLaunchDaemon() {
    
    jamflaunchDaemon="/Library/LaunchDaemons/com.jamfsoftware.task.1.plist"

    if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then

        if [[ $(/bin/launchctl list | grep com.jamfsoftware.task.E) ]]; then
            updateScriptLog "PRE-FLIGHT CHECK: DEBUG MODE: Normally, 'jamf' binary check-in would be temporarily disabled"
        else
            updateScriptLog "QUIT SCRIPT: DEBUG MODE: Normally, 'jamf' binary check-in would be re-enabled"
        fi

    else

        while [[ ! -f "${jamflaunchDaemon}" ]] ; do
            updateScriptLog "PRE-FLIGHT CHECK: Waiting for installation of ${jamflaunchDaemon}"
            sleep 0.1
        done

        if [[ $(/bin/launchctl list | grep com.jamfsoftware.task.E) ]]; then

            updateScriptLog "PRE-FLIGHT CHECK: Temporarily disable 'jamf' binary check-in"
            /bin/launchctl bootout system "${jamflaunchDaemon}"

        else

            updateScriptLog "QUIT SCRIPT: Re-enabling 'jamf' binary check-in"
            updateScriptLog "QUIT SCRIPT: 'jamf' binary check-in daemon not loaded, attempting to bootstrap and start"
            result="0"

            until [ $result -eq 3 ]; do

                /bin/launchctl bootstrap system "${jamflaunchDaemon}" && /bin/launchctl start "${jamflaunchDaemon}"
                result="$?"

                if [ $result = 3 ]; then
                    updateScriptLog "QUIT SCRIPT: Staring 'jamf' binary check-in daemon"
                else
                    updateScriptLog "QUIT SCRIPT: Failed to start 'jamf' binary check-in daemon"
                fi

            done

        fi

    fi

}

toggleJamfLaunchDaemon



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate / install swiftDialog (Thanks big bunches, @acodega!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogInstall() {

    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$(curl -L --silent --fail "https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"

    updateScriptLog "PRE-FLIGHT CHECK: Installing swiftDialog..."

    # Create temporary working directory
    workDirectory=$( /usr/bin/basename "$0" )
    tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )

    # Download the installer package
    /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"

    # Verify the download
    teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')

    # Install the package if Team ID validates
    if [[ "$expectedDialogTeamID" == "$teamID" ]]; then

        /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
        sleep 2
        dialogVersion=$( /usr/local/bin/dialog --version )
        updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version ${dialogVersion} installed; proceeding..."

    else

        # Display a so-called "simple" dialog if Team ID fails to validate
        osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Dialog Team ID verification failed\r\r" with title "Setup Your Mac: Error" buttons {"Close"} with icon caution'
        completionActionOption="Quit"
        exitCode="1"
        quitScript

    fi

    # Remove the temporary working directory when done
    /bin/rm -Rf "$tempDirectory"

}



function dialogCheck() {

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "PRE-FLIGHT CHECK: # # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    # Check for Dialog and install if not found
    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then

        updateScriptLog "PRE-FLIGHT CHECK: swiftDialog not found. Installing..."
        dialogInstall

    else

        dialogVersion=$(/usr/local/bin/dialog --version)
        if [[ "${dialogVersion}" < "${swiftDialogMinimumRequiredVersion}" ]]; then
            
            updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version ${dialogVersion} found but swiftDialog ${swiftDialogMinimumRequiredVersion} or newer is required; updating..."
            dialogInstall
            
        else

        updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version ${dialogVersion} found; proceeding..."

        fi
    
    fi

}

dialogCheck



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate `supportTeam` variables are populated
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -z $supportTeamName ]]; then
    updateScriptLog "PRE-FLIGHT CHECK: 'supportTeamName' must be populated to proceed; exiting"
    exit 1
fi

if [[ -z $supportTeamPhone && -z $supportTeamEmail && -z $supportKB ]]; then
    updateScriptLog "PRE-FLIGHT CHECK: At least ONE 'supportTeam' variable must be populated to proceed; exiting"
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Complete
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "PRE-FLIGHT CHECK: Complete"



####################################################################################################
#
# Dialog Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# infobox-related variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

macOSproductVersion="$( sw_vers -productVersion )"
macOSbuildVersion="$( sw_vers -buildVersion )"
serialNumber=$( ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}' )
timestamp="$( date '+%Y-%m-%d-%H%M%S' )"
dialogVersion=$( /usr/local/bin/dialog --version )



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reflect Debug Mode in `infotext` (i.e., bottom, left-hand corner of each dialog)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

case ${debugMode} in
    "true"      ) scriptVersion="DEBUG MODE | Dialog: v${dialogVersion} • Setup Your Mac: v${scriptVersion}" ;;
    "verbose"   ) scriptVersion="VERBOSE DEBUG MODE | Dialog: v${dialogVersion} • Setup Your Mac: v${scriptVersion}" ;;
esac



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set JAMF binary, Dialog path and Command Files
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

jamfBinary="/usr/local/bin/jamf"
dialogBinary="/usr/local/bin/dialog"
welcomeJSONFile=$( mktemp -u /var/tmp/welcomeJSONFile.XXX )
welcomeCommandFile=$( mktemp -u /var/tmp/dialogCommandFileWelcome.XXX )
setupYourMacCommandFile=$( mktemp -u /var/tmp/dialogCommandFileSetupYourMac.XXX )
failureCommandFile=$( mktemp -u /var/tmp/dialogCommandFileFailure.XXX )



####################################################################################################
#
# Welcome dialog
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Welcome" dialog Title, Message and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

welcomeTitle="Happy $( date +'%A' ), ${loggedInUserFirstname}!  \nWelcome to your new ${modelName}"

welcomeMessage="Please enter the **required** information for your ${modelName}, select your preferred **Configuration** then click **Continue** to start applying settings to your new Mac. \n\nOnce completed, the **Wait** button will be enabled and you‘ll be able to review the results before restarting your ${modelName}."

if [[ -n "${supportTeamName}" ]]; then

    welcomeMessage+="\n\nIf you need assistance, please contact the **${supportTeamName}**:  \n"

    if [[ -n "${supportTeamPhone}" ]]; then
        welcomeMessage+="- **Telephone**: ${supportTeamPhone}\n"
    fi

    if [[ -n "${supportTeamEmail}" ]]; then
        welcomeMessage+="- **Email**: ${supportTeamEmail}\n"
    fi

    if [[ -n "${supportTeamWebsite}" ]]; then
        welcomeMessage+="- **Web**: ${supportTeamHyperlink}\n"
    fi

    if [[ -n "${supportKB}" ]]; then
        welcomeMessage+="- **Knowledge Base Article:** ${supportTeamErrorKB}\n"
    fi

fi

welcomeMessage+="\n\n---"

if { [[ "${promptForConfiguration}" == "true" ]] && [[ "${welcomeDialog}" != "messageOnly" ]]; } then
    welcomeMessage+="  \n\n#### Configurations  \n- **${configurationOneName}:** ${configurationOneDescription}  \n- **${configurationTwoName}:** ${configurationTwoDescription}  \n- **${configurationThreeName}:** ${configurationThreeDescription}"
else
    welcomeMessage=${welcomeMessage//", select your preferred **Configuration**"/}
fi

if [[ -n "${brandingBanner}" ]]; then
    welcomeBannerImage="${brandingBanner}"
else
    welcomeBannerImage="https://img.freepik.com/free-vector/green-abstract-geometric-wallpaper_52683-29623.jpg" # Image by pikisuperstar on Freepik
fi

if [[ "${brandingBannerDisplayText}" == "true" ]]; then welcomeBannerText="Happy $( date +'%A' ), ${loggedInUserFirstname}!  \nWelcome to your new ${modelName}";
else welcomeBannerText=""; fi
welcomeCaption="Please review the above video, then click Continue."
welcomeVideoID="vimeoid=877821811"

# Check if the custom welcomeBannerImage is available, and if not, use a alternative image
if curl -L --output /dev/null --silent --head --fail "$welcomeBannerImage" || [ -f "$welcomeBannerImage" ]; then
    updateScriptLog "WELCOME DIALOG: welcomeBannerImage is available, using it"
else
    updateScriptLog "WELCOME DIALOG: welcomeBannerImage is not available, using a default image"
    welcomeBannerImage="https://img.freepik.com/free-vector/green-abstract-geometric-wallpaper_52683-29623.jpg" # Image by pikisuperstar on Freepik
fi

# Cache the hosted custom welcomeBannerImage
if [[ $welcomeBannerImage == *"http"* ]]; then
    welcomeBannerImageFileName=$( echo ${welcomeBannerImage} | awk -F '/' '{print $NF}' )
    updateScriptLog "WELCOME DIALOG: Auto-caching hosted '$welcomeBannerImageFileName' …"
    curl -L --location --silent "$welcomeBannerImage" -o "/var/tmp/${welcomeBannerImageFileName}"
    welcomeBannerImage="/var/tmp/${welcomeBannerImageFileName}"
fi

# Welcome icon set to either light or dark, based on user's Apperance setting (thanks, @mm2270!)
appleInterfaceStyle=$( /usr/bin/defaults read /Users/"${loggedInUser}"/Library/Preferences/.GlobalPreferences.plist AppleInterfaceStyle 2>&1 )
if [[ "${appleInterfaceStyle}" == "Dark" ]]; then
    if [[ -n "$brandingIconDark" ]]; then welcomeIcon="$brandingIconDark";
    else welcomeIcon="https://cdn-icons-png.flaticon.com/512/740/740878.png"; fi
else
    if [[ -n "$brandingIconLight" ]]; then welcomeIcon="$brandingIconLight";
    else welcomeIcon="https://cdn-icons-png.flaticon.com/512/979/979585.png"; fi
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Welcome" Video Settings and Features
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

welcomeVideo="--title \"$welcomeTitle\" \
--videocaption \"$welcomeCaption\" \
--video \"$welcomeVideoID\" \
--infotext \"$scriptVersion\" \
--button1text \"Continue …\" \
--autoplay \
--moveable \
--ontop \
--width '800' \
--height '600' \
--commandfile \"$welcomeCommandFile\" "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Welcome" JSON Conditionals (thanks, @rougegoat!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Text Fields
if [ "$prefillUsername" == "true" ]; then usernamePrefil=',"value" : "'${loggedInUser}'"'; fi
if [ "$prefillRealname" == "true" ]; then realnamePrefil=',"value" : "'${loggedInUserFullname}'"'; fi
if [ "$promptForUsername" == "true" ]; then usernameJSON='{ "title" : "User Name","required" : false,"prompt" : "User Name"'${usernamePrefil}'},'; fi
if [ "$promptForRealName" == "true" ]; then realNameJSON='{ "title" : "Full Name","required" : false,"prompt" : "Full Name"'${realnamePrefil}'},'; fi
if [ "$promptForEmail" == "true" ]; then
    emailJSON='{   "title" : "E-mail",
        "required" : true,
        "prompt" : "E-mail Address",
        "regex" : "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
        "regexerror" : "Please enter a valid email address."
    },'
fi
if [ "$promptForComputerName" == "true" ]; then compNameJSON='{ "title" : "Computer Name","required" : false,"prompt" : "Computer Name" },'; fi
if [ "$promptForAssetTag" == "true" ]; then
    assetTagJSON='{   "title" : "Asset Tag",
        "required" : true,
        "prompt" : "Please enter the (at least) seven-digit Asset Tag",
        "regex" : "^(AP|IP|CD)?[0-9]{7,}$",
        "regexerror" : "Please enter (at least) seven digits for the Asset Tag, optionally preceded by either AP, IP or CD."
    },'
fi
if [ "$promptForRoom" == "true" ]; then roomJSON='{ "title" : "Room","required" : false,"prompt" : "Optional" },'; fi
if [[ "$promptForPosition" == "true" && -z "$positionListRaw" ]]; then positionJSON='{ "title" : "Position","required" : false,"prompt" : "Position" },'; fi

textFieldJSON="${usernameJSON}${realNameJSON}${emailJSON}${compNameJSON}${assetTagJSON}${positionJSON}${roomJSON}"
textFieldJSON=$( echo ${textFieldJSON} | sed 's/,$//' )

# Dropdowns
if [ "$promptForBuilding" == "true" ]; then
    if [ -n "$buildingsListRaw" ]; then
    buildingJSON='{
            "title" : "Building",
            "default" : "",
            "required" : true,
            "values" : [
                '${buildingsList}'
            ]
        },'
    fi
fi

if [ "$promptForDepartment" == "true" ]; then
    if [ -n "$departmentListRaw" ]; then
    departmentJSON='{
            "title" : "Department",
            "default" : "",
            "required" : true,
            "values" : [
                '${departmentList}'
            ]
        },'
    fi
fi

if [ "$promptForPosition" == "true" ]; then
    if [ -n "${positionListRaw}" ]; then
    positionSelectJSON='{
            "title" : "Position",
            "default" : "",
            "required" : true,
            "values" : [
                '${positionList}'
            ]
        },'
    fi
fi

if [ "$promptForConfiguration" == "true" ] && [ -z "${presetConfiguration}" ]; then
    configurationJSON='{
            "title" : "Configuration",
            "style" : "radio",
            "default" : "'"${configurationOneName}"'",
            "values" : [
                "'"${configurationOneName}"'",
                "'"${configurationTwoName}"'",
                "'"${configurationThreeName}"'"
            ]
        }'
fi

selectItemsJSON="${buildingJSON}${departmentJSON}${positionSelectJSON}${configurationJSON}"
selectItemsJSON=$( echo $selectItemsJSON | sed 's/,$//' )



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Welcome" JSON for Capturing User Input (thanks, @bartreardon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

welcomeJSON='
{
    "commandfile" : "'"${welcomeCommandFile}"'",
    "bannerimage" : "'"${welcomeBannerImage}"'",
    "bannertext" : "'"${welcomeBannerText}"'",
    "title" : "'"${welcomeTitle}"'",
    "message" : "'"${welcomeMessage}"'",
    "icon" : "'"${welcomeIcon}"'",
    "infobox" : "Analyzing …",
    "iconsize" : "198.0",
    "button1text" : "Continue",
    "button2text" : "Quit",
    "infotext" : "'"${scriptVersion}"'",
    "blurscreen" : "true",
    "ontop" : "true",
    "titlefont" : "shadow=true, size=36, colour=#FFFDF4",
    "messagefont" : "size=14",
    "textfield" : [
        '${textFieldJSON}'
    ],
    "selectitems" : [
        '${selectItemsJSON}'
    ],
    "height" : "800"
}
'



####################################################################################################
#
# Setup Your Mac dialog
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Setup Your Mac" dialog Title, Message, Icon and Overlay Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

title="Setting up ${loggedInUserFirstname}‘s ${modelName}"
message="Please wait while the following apps are installed …"
if [[ -n "${brandingBanner}" ]]; then
    bannerImage="${brandingBanner}"
else
    bannerImage="https://img.freepik.com/free-vector/green-abstract-geometric-wallpaper_52683-29623.jpg" # Image by pikisuperstar on Freepik
fi

if [[ "${brandingBannerDisplayText}" == "true" ]] ; then
    bannerText="Setting up ${loggedInUserFirstname}‘s ${modelName}";
else
    bannerText=""
fi

if [ -n "$supportTeamName" ]; then
  helpmessage+="If you need assistance, please contact:  \n\n**${supportTeamName}**  \n"
fi

if [ -n "$supportTeamPhone" ]; then
  helpmessage+="- **Telephone:** ${supportTeamPhone}  \n"
fi

if [ -n "$supportTeamEmail" ]; then
  helpmessage+="- **Email:** ${supportTeamEmail}  \n"
fi

if [ -n "$supportTeamWebsite" ]; then
    helpmessage+="- **Web**: ${supportTeamHyperlink}  \n"
fi

if [ -n "$supportKB" ]; then
  helpmessage+="- **Knowledge Base Article:** ${supportTeamErrorKB}  \n"
fi

helpmessage+="\n**Computer Information:**  \n"
helpmessage+="- **Operating System:** ${macOSproductVersion} (${macOSbuildVersion})  \n"
helpmessage+="- **Serial Number:** ${serialNumber}  \n"
helpmessage+="- **Dialog:** ${dialogVersion}  \n"
helpmessage+="- **Started:** ${timestamp}"

infobox="Analyzing input …" # Customize at "Update Setup Your Mac's infobox"

# Check if the custom bannerImage is available, and if not, use a alternative image
if curl -L --output /dev/null --silent --head --fail "$bannerImage" || [ -f "$bannerImage" ]; then
    updateScriptLog "WELCOME DIALOG: bannerImage is available"
else
    updateScriptLog "WELCOME DIALOG: bannerImage is not available, using alternative image"
    bannerImage="https://img.freepik.com/free-vector/green-abstract-geometric-wallpaper_52683-29623.jpg" # Image by pikisuperstar on Freepik
fi

# Create `overlayicon` from Self Service's custom icon (thanks, @meschwartz!)
xxd -p -s 260 "$(defaults read /Library/Preferences/com.jamfsoftware.jamf self_service_app_path)"/Icon$'\r'/..namedfork/rsrc | xxd -r -p > /var/tmp/overlayicon.icns
overlayicon="/var/tmp/overlayicon.icns"

# Uncomment to use generic, Self Service icon as overlayicon
# overlayicon="https://ics.services.jamfcloud.com/icon/hash_aa63d5813d6ed4846b623ed82acdd1562779bf3716f2d432a8ee533bba8950ee"

# Set initial icon based on whether the Mac is a desktop or laptop
if system_profiler SPPowerDataType | grep -q "Battery Power"; then
    icon="SF=laptopcomputer.and.arrow.down,weight=semibold,colour1=#ef9d51,colour2=#ef7951"
else
    icon="SF=desktopcomputer.and.arrow.down,weight=semibold,colour1=#ef9d51,colour2=#ef7951"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Setup Your Mac" dialog Settings and Features
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogSetupYourMacCMD="$dialogBinary \
--bannerimage \"$bannerImage\" \
--bannertext \"$bannerText\" \
--title \"$title\" \
--message \"$message\" \
--helpmessage \"$helpmessage\" \
--icon \"$icon\" \
--infobox \"${infobox}\" \
--progress \
--progresstext \"Initializing configuration …\" \
--button1text \"Wait\" \
--button1disabled \
--infotext \"$scriptVersion\" \
--titlefont 'shadow=true, size=36, colour=#FFFDF4' \
--messagefont 'size=14' \
--height '800' \
--position 'centre' \
--blurscreen \
--ontop \
--overlayicon \"$overlayicon\" \
--quitkey k \
--commandfile \"$setupYourMacCommandFile\" "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# [SYM-Helper] "Setup Your Mac" policies to execute (Thanks, Obi-@smithjw!)
#
# For each configuration step, specify:
# - listitem: The text to be displayed in the list
# - icon: The hash of the icon to be displayed on the left
#   - See: https://vimeo.com/772998915
# - progresstext: The text to be displayed below the progress bar
# - trigger: The Jamf Pro Policy Custom Event Name
# - validation: [ {absolute path} | Local | Remote | None | Recon ]
#   See: https://snelson.us/2023/01/setup-your-mac-validation/
#       - {absolute path} (simulates pre-v1.6.0 behavior, for example: "/Applications/Microsoft Teams classic.app/Contents/Info.plist")
#       - Local (for validation within this script, for example: "filevault")
#       - Remote (for validation via a single-script Jamf Pro policy, for example: "symvGlobalProtect")
#       - None (for triggers which don't require validation; always evaluates as successful)
#       - Recon (to update the computer's inventory with your Jamf Pro server)
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Thanks, @wakco: If you would prefer to get your policyJSON externally replace it with:
#  - policyJSON="$(cat /path/to/file.json)" # For getting from a file, replacing /path/to/file.json with the path to your file, or
#  - policyJSON="$(curl -sL https://server.name/jsonquery)" # For a URL, replacing https://server.name/jsonquery with the URL of your file.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Thanks, @astrugatch: I added this line to global variables:
# jsonURL=${10} # URL Hosting JSON for policy_array
#
# And this line replaces the entirety of the policy_array (~ line 503):
# policy_array=("$(curl -sL $jsonURL)")
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Select `policyJSON` based on Configuration selected in "Welcome" dialog (thanks, @drtaru!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function policyJSONConfiguration() {

    outputLineNumberInVerboseDebugMode

    updateScriptLog "WELCOME DIALOG: PolicyJSON Configuration: $symConfiguration"

    case ${symConfiguration} in

        "${configurationOneName}" )

            overlayoverride=""
            policyJSON='
            {
                "steps": [
                    {
                        "listitem": "Rosetta",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_8bac19160fabb0c8e7bac97b37b51d2ac8f38b7100b6357642d9505645d37b52",
                        "progresstext": "Rosetta enables a Mac with Apple silicon to use apps built for a Mac with an Intel processor.",
                        "trigger_list": [
                            {
                                "trigger": "rosettaInstall",
                                "validation": "None"
                            },
                            {
                                "trigger": "rosetta",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "FileVault Disk Encryption",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_f9ba35bd55488783456d64ec73372f029560531ca10dfa0e8154a46d7732b913",
                        "progresstext": "FileVault is built-in to macOS and provides full-disk encryption to help prevent unauthorized access to your Mac.",
                        "trigger_list": [
                            {
                                "trigger": "filevault",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "Sophos Endpoint",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_c70f1acf8c96b99568fec83e165d2a534d111b0510fb561a283d32aa5b01c60c",
                        "progresstext": "You’ll enjoy next-gen protection with Sophos Endpoint which doesn’t rely on signatures to catch malware.",
                        "trigger_list": [
                            {
                                "trigger": "sophosEndpoint",
                                "validation": "/Applications/Sophos/Sophos Endpoint.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Sophos Endpoint Services (Remote)",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_0f68be689684a00a3a054d71a31e43e2362f96c16efa5a560fb61bc1bf41901c",
                        "progresstext": "Remotely validating Sophos Endpoint services …",
                        "trigger_list": [
                            {
                                "trigger": "symvSophosEndpointRTS",
                                "validation": "Remote"
                            }
                        ]
                    },
                    {
                        "listitem": "Palo Alto GlobalProtect",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_acbf39d8904ad1a772cf71c45d93e373626d379a24f8b1283b88134880acb8ef",
                        "progresstext": "Use Palo Alto GlobalProtect to establish a Virtual Private Network (VPN) connection to Church headquarters.",
                        "trigger_list": [
                            {
                                "trigger": "globalProtect",
                                "validation": "/Applications/GlobalProtect.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Palo Alto GlobalProtect Services (Remote)",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_709e8bdf0019e8faf9df85ec0a68545bfdb8bfa1227ac9bed9bba40a1fa8ff42",
                        "progresstext": "Remotely validating Palo Alto GlobalProtect services …",
                        "trigger_list": [
                            {
                                "trigger": "symvGlobalProtect",
                                "validation": "Remote"
                            }
                        ]
                    },
                    {
                        "listitem": "Final Configuration",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_4723e3e341a7e11e6881e418cf91b157fcc081bdb8948697750e5da3562df728",
                        "progresstext": "Finalizing Configuration …",
                        "trigger_list": [
                            {
                                "trigger": "finalConfiguration",
                                "validation": "None"
                            },
                            {
                                "trigger": "reconAtReboot",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Computer Inventory",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_ff2147a6c09f5ef73d1c4406d00346811a9c64c0b6b7f36eb52fcb44943d26f9",
                        "progresstext": "A listing of your Mac’s apps and settings — its inventory — is sent automatically to the Jamf Pro server daily.",
                        "trigger_list": [
                            {
                                "trigger": "recon",
                                "validation": "recon"
                            }
                        ]
                    }
                ]
            }
            '
            ;;

        "${configurationTwoName}" )

            overlayoverride=""
            policyJSON='
            {
                "steps": [
                    {
                        "listitem": "Rosetta",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_8bac19160fabb0c8e7bac97b37b51d2ac8f38b7100b6357642d9505645d37b52",
                        "progresstext": "Rosetta enables a Mac with Apple silicon to use apps built for a Mac with an Intel processor.",
                        "trigger_list": [
                            {
                                "trigger": "rosettaInstall",
                                "validation": "None"
                            },
                            {
                                "trigger": "rosetta",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "FileVault Disk Encryption",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_f9ba35bd55488783456d64ec73372f029560531ca10dfa0e8154a46d7732b913",
                        "progresstext": "FileVault is built-in to macOS and provides full-disk encryption to help prevent unauthorized access to your Mac.",
                        "trigger_list": [
                            {
                                "trigger": "filevault",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "Sophos Endpoint",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_c70f1acf8c96b99568fec83e165d2a534d111b0510fb561a283d32aa5b01c60c",
                        "progresstext": "You’ll enjoy next-gen protection with Sophos Endpoint which doesn’t rely on signatures to catch malware.",
                        "trigger_list": [
                            {
                                "trigger": "sophosEndpoint",
                                "validation": "/Applications/Sophos/Sophos Endpoint.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Sophos Endpoint Services (Local)",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_0f68be689684a00a3a054d71a31e43e2362f96c16efa5a560fb61bc1bf41901c",
                        "progresstext": "Locally validating Sophos Endpoint services …",
                        "trigger_list": [
                            {
                                "trigger": "sophosEndpointServices",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "Palo Alto GlobalProtect",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_acbf39d8904ad1a772cf71c45d93e373626d379a24f8b1283b88134880acb8ef",
                        "progresstext": "Use Palo Alto GlobalProtect to establish a Virtual Private Network (VPN) connection to Church headquarters.",
                        "trigger_list": [
                            {
                                "trigger": "globalProtect",
                                "validation": "/Applications/GlobalProtect.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Palo Alto GlobalProtect Services (Local)",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_709e8bdf0019e8faf9df85ec0a68545bfdb8bfa1227ac9bed9bba40a1fa8ff42",
                        "progresstext": "Locally validating Palo Alto GlobalProtect services …",
                        "trigger_list": [
                            {
                                "trigger": "globalProtect",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "Microsoft 365",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_1801d1fdd81e19ce5eb0e567371377e7995bff32947adb7a94c5feea760edcb5",
                        "progresstext": "Office is now Microsoft 365. Create, share, and collaborate with your favorite apps — all in one place — with Microsoft 365.",
                        "trigger_list": [
                            {
                                "trigger": "microsoftOffice365",
                                "validation": "/Applications/Microsoft Outlook.app/Contents/Info.plist"
                            },
                            {
                                "trigger": "symvMicrosoftOffice365",
                                "validation": "Remote"
                            }
                        ]
                    },
                    {
                        "listitem": "Microsoft Teams",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_dcb65709dba6cffa90a5eeaa54cb548d5ecc3b051f39feadd39e02744f37c19e",
                        "progresstext": "Microsoft Teams is a hub for teamwork in Office 365. Keep all your team’s chats, meetings and files together in one place.",
                        "trigger_list": [
                            {
                                "trigger": "microsoftTeams",
                                "validation": "/Applications/Microsoft Teams classic.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Final Configuration",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_4723e3e341a7e11e6881e418cf91b157fcc081bdb8948697750e5da3562df728",
                        "progresstext": "Finalizing Configuration …",
                        "trigger_list": [
                            {
                                "trigger": "finalConfiguration",
                                "validation": "None"
                            },
                            {
                                "trigger": "reconAtReboot",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Computer Inventory",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_ff2147a6c09f5ef73d1c4406d00346811a9c64c0b6b7f36eb52fcb44943d26f9",
                        "progresstext": "A listing of your Mac’s apps and settings — its inventory — is sent automatically to the Jamf Pro server daily.",
                        "trigger_list": [
                            {
                                "trigger": "recon",
                                "validation": "recon"
                            }
                        ]
                    }
                ]
            }
            '
            ;;

        "${configurationThreeName}" )

            overlayoverride=""
            policyJSON='
            {
                "steps": [
                    {
                        "listitem": "Rosetta",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_8bac19160fabb0c8e7bac97b37b51d2ac8f38b7100b6357642d9505645d37b52",
                        "progresstext": "Rosetta enables a Mac with Apple silicon to use apps built for a Mac with an Intel processor.",
                        "trigger_list": [
                            {
                                "trigger": "rosettaInstall",
                                "validation": "None"
                            },
                            {
                                "trigger": "rosetta",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "FileVault Disk Encryption",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_f9ba35bd55488783456d64ec73372f029560531ca10dfa0e8154a46d7732b913",
                        "progresstext": "FileVault is built-in to macOS and provides full-disk encryption to help prevent unauthorized access to your Mac.",
                        "trigger_list": [
                            {
                                "trigger": "filevault",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "Sophos Endpoint",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_c70f1acf8c96b99568fec83e165d2a534d111b0510fb561a283d32aa5b01c60c",
                        "progresstext": "You’ll enjoy next-gen protection with Sophos Endpoint which doesn’t rely on signatures to catch malware.",
                        "trigger_list": [
                            {
                                "trigger": "sophosEndpoint",
                                "validation": "/Applications/Sophos/Sophos Endpoint.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Sophos Endpoint Services (Local)",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_0f68be689684a00a3a054d71a31e43e2362f96c16efa5a560fb61bc1bf41901c",
                        "progresstext": "Locally validating Sophos Endpoint services …",
                        "trigger_list": [
                            {
                                "trigger": "sophosEndpointServices",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "Sophos Endpoint Services (Remote)",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_0f68be689684a00a3a054d71a31e43e2362f96c16efa5a560fb61bc1bf41901c",
                        "progresstext": "Remotely validating Sophos Endpoint services …",
                        "trigger_list": [
                            {
                                "trigger": "symvSophosEndpointRTS",
                                "validation": "Remote"
                            }
                        ]
                    },
                    {
                        "listitem": "Palo Alto GlobalProtect",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_acbf39d8904ad1a772cf71c45d93e373626d379a24f8b1283b88134880acb8ef",
                        "progresstext": "Use Palo Alto GlobalProtect to establish a Virtual Private Network (VPN) connection to Church headquarters.",
                        "trigger_list": [
                            {
                                "trigger": "globalProtect",
                                "validation": "/Applications/GlobalProtect.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Palo Alto GlobalProtect Services (Local)",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_709e8bdf0019e8faf9df85ec0a68545bfdb8bfa1227ac9bed9bba40a1fa8ff42",
                        "progresstext": "Locally validating Palo Alto GlobalProtect services …",
                        "trigger_list": [
                            {
                                "trigger": "globalProtect",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "Palo Alto GlobalProtect Services (Remote)",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_709e8bdf0019e8faf9df85ec0a68545bfdb8bfa1227ac9bed9bba40a1fa8ff42",
                        "progresstext": "Remotely validating Palo Alto GlobalProtect services …",
                        "trigger_list": [
                            {
                                "trigger": "symvGlobalProtect",
                                "validation": "Remote"
                            }
                        ]
                    },
                    {
                        "listitem": "Microsoft 365",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_1801d1fdd81e19ce5eb0e567371377e7995bff32947adb7a94c5feea760edcb5",
                        "progresstext": "Office is now Microsoft 365. Create, share, and collaborate with your favorite apps — all in one place — with Microsoft 365.",
                        "trigger_list": [
                            {
                                "trigger": "microsoftOffice365",
                                "validation": "/Applications/Microsoft Outlook.app/Contents/Info.plist"
                            },
                            {
                                "trigger": "symvMicrosoftOffice365",
                                "validation": "Remote"
                            }
                        ]
                    },
                    {
                        "listitem": "Microsoft Teams",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_dcb65709dba6cffa90a5eeaa54cb548d5ecc3b051f39feadd39e02744f37c19e",
                        "progresstext": "Microsoft Teams is a hub for teamwork in Office 365. Keep all your team’s chats, meetings and files together in one place.",
                        "trigger_list": [
                            {
                                "trigger": "microsoftTeams",
                                "validation": "/Applications/Microsoft Teams classic.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Adobe Acrobat Reader",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_988b669ca27eab93a9bcd53bb7e2873fb98be4eaa95ae8974c14d611bea1d95f",
                        "progresstext": "Views, prints, and comments on PDF documents, and connects to Adobe Document Cloud.",
                        "trigger_list": [
                            {
                                "trigger": "adobeAcrobatReader",
                                "validation": "/Applications/Adobe Acrobat Reader.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Google Chrome",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_12d3d198f40ab2ac237cff3b5cb05b09f7f26966d6dffba780e4d4e5325cc701",
                        "progresstext": "Google Chrome is a browser that combines a minimal design with sophisticated technology to make the Web faster.",
                        "trigger_list": [
                            {
                                "trigger": "googleChrome",
                                "validation": "/Applications/Google Chrome.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Final Configuration",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_4723e3e341a7e11e6881e418cf91b157fcc081bdb8948697750e5da3562df728",
                        "progresstext": "Finalizing Configuration …",
                        "trigger_list": [
                            {
                                "trigger": "finalConfiguration",
                                "validation": "None"
                            },
                            {
                                "trigger": "reconAtReboot",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Computer Inventory",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_ff2147a6c09f5ef73d1c4406d00346811a9c64c0b6b7f36eb52fcb44943d26f9",
                        "progresstext": "A listing of your Mac’s apps and settings — its inventory — is sent automatically to the Jamf Pro server daily.",
                        "trigger_list": [
                            {
                                "trigger": "recon",
                                "validation": "recon"
                            }
                        ]
                    }
                ]
            }
            '
            ;;

        * ) # Catch-all (i.e., used when `welcomeDialog` is set to `video`, `messageOnly` or `false`)

            overlayoverride=""
            policyJSON='
            {
                "steps": [
                    {
                        "listitem": "Rosetta",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_8bac19160fabb0c8e7bac97b37b51d2ac8f38b7100b6357642d9505645d37b52",
                        "progresstext": "Rosetta enables a Mac with Apple silicon to use apps built for a Mac with an Intel processor.",
                        "trigger_list": [
                            {
                                "trigger": "rosettaInstall",
                                "validation": "None"
                            },
                            {
                                "trigger": "rosetta",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "FileVault Disk Encryption",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_f9ba35bd55488783456d64ec73372f029560531ca10dfa0e8154a46d7732b913",
                        "progresstext": "FileVault is built-in to macOS and provides full-disk encryption to help prevent unauthorized access to your Mac.",
                        "trigger_list": [
                            {
                                "trigger": "filevault",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "Sophos Endpoint",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_c70f1acf8c96b99568fec83e165d2a534d111b0510fb561a283d32aa5b01c60c",
                        "progresstext": "You’ll enjoy next-gen protection with Sophos Endpoint which doesn’t rely on signatures to catch malware.",
                        "trigger_list": [
                            {
                                "trigger": "sophosEndpoint",
                                "validation": "/Applications/Sophos/Sophos Endpoint.app/Contents/Info.plist"
                            },
                            {
                                "trigger": "symvSophosEndpointRTS",
                                "validation": "Remote"
                            }
                        ]
                    },
                    {
                        "listitem": "Palo Alto GlobalProtect",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_acbf39d8904ad1a772cf71c45d93e373626d379a24f8b1283b88134880acb8ef",
                        "progresstext": "Use Palo Alto GlobalProtect to establish a Virtual Private Network (VPN) connection to Church headquarters.",
                        "trigger_list": [
                            {
                                "trigger": "globalProtect",
                                "validation": "/Applications/GlobalProtect.app/Contents/Info.plist"
                            },
                            {
                                "trigger": "symvGlobalProtect",
                                "validation": "Remote"
                            }
                        ]
                    },
                    {
                        "listitem": "Final Configuration",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_4723e3e341a7e11e6881e418cf91b157fcc081bdb8948697750e5da3562df728",
                        "progresstext": "Finalizing Configuration …",
                        "trigger_list": [
                            {
                                "trigger": "finalConfiguration",
                                "validation": "None"
                            },
                            {
                                "trigger": "reconAtReboot",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Computer Inventory",
                        "icon": "https://ics.services.jamfcloud.com/icon/hash_ff2147a6c09f5ef73d1c4406d00346811a9c64c0b6b7f36eb52fcb44943d26f9",
                        "progresstext": "A listing of your Mac’s apps and settings — its inventory — is sent automatically to the Jamf Pro server daily.",
                        "trigger_list": [
                            {
                                "trigger": "recon",
                                "validation": "recon"
                            }
                        ]
                    }
                ]
            }
            '
            ;;

    esac

}



####################################################################################################
#
# Failure dialog
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Failure" dialog Title, Message and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

failureTitle="Failure Detected"
failureMessage="Placeholder message; update in the 'finalise' function"
failureIcon="SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Failure" dialog Settings and Features
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogFailureCMD="$dialogBinary \
--moveable \
--title \"$failureTitle\" \
--message \"$failureMessage\" \
--icon \"$failureIcon\" \
--iconsize 125 \
--width 625 \
--height 45% \
--position topright \
--button1text \"Close\" \
--infotext \"$scriptVersion\" \
--titlefont 'size=22' \
--messagefont 'size=14' \
--overlayicon \"$overlayicon\" \
--commandfile \"$failureCommandFile\" "



#------------------------ With the execption of the `finalise` function, -------------------------#
#------------------------ edits below these line are optional. -----------------------------------#



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Dynamically set `button1text` based on the value of `completionActionOption`
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

case ${completionActionOption} in

    "Shut Down" )
        button1textCompletionActionOption="Shutting Down …"
        progressTextCompletionAction="shut down and "
        ;;

    "Shut Down "* )
        button1textCompletionActionOption="Shut Down"
        progressTextCompletionAction="shut down and "
        ;;

    "Restart" )
        button1textCompletionActionOption="Restarting …"
        progressTextCompletionAction="restart and "
        ;;

    "Restart "* )
        button1textCompletionActionOption="Restart"
        progressTextCompletionAction="restart and "
        ;;

    "Log Out" )
        button1textCompletionActionOption="Logging Out …"
        progressTextCompletionAction="log out and "
        ;;

    "Log Out "* )
        button1textCompletionActionOption="Log Out"
        progressTextCompletionAction="log out and "
        ;;

    "Sleep"* )
        button1textCompletionActionOption="Close"
        progressTextCompletionAction=""
        ;;

    "Quit" )
        button1textCompletionActionOption="Quit"
        progressTextCompletionAction=""
        ;;

    * )
        button1textCompletionActionOption="Close"
        progressTextCompletionAction=""
        ;;

esac



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Output Line Number in `verbose` Debug Mode (thanks, @bartreardon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function outputLineNumberInVerboseDebugMode() {
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${BASH_LINENO[0]} # # #" ; fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Run command as logged-in user (thanks, @scriptingosx!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function runAsUser() {

    updateScriptLog "Run \"$@\" as \"$loggedInUserID\" … "
    launchctl asuser "$loggedInUserID" sudo -u "$loggedInUser" "$@"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Calculate Free Disk Space
# Disk Usage with swiftDialog (https://snelson.us/2022/11/disk-usage-with-swiftdialog-0-0-2/)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function calculateFreeDiskSpace() {

    freeSpace=$( diskutil info / | grep -E 'Free Space|Available Space|Container Free Space' | awk -F ":\s*" '{ print $2 }' | awk -F "(" '{ print $1 }' | xargs )
    freeBytes=$( diskutil info / | grep -E 'Free Space|Available Space|Container Free Space' | awk -F "(\\\(| Bytes\\\))" '{ print $2 }' )
    diskBytes=$( diskutil info / | grep -E 'Total Space' | awk -F "(\\\(| Bytes\\\))" '{ print $2 }' )
    freePercentage=$( echo "scale=2; ( $freeBytes * 100 ) / $diskBytes" | bc )
    diskSpace="$freeSpace free (${freePercentage}% available)"

    updateScriptLog "${1}: Disk Space: ${diskSpace}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update the "Welcome" dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateWelcome(){
    # updateScriptLog "WELCOME DIALOG: $1"
    echo "$1" >> "$welcomeCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update the "Setup Your Mac" dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateSetupYourMac() {
    updateScriptLog "SETUP YOUR MAC DIALOG: $1"
    echo "$1" >> "$setupYourMacCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update the "Failure" dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateFailure(){
    updateScriptLog "FAILURE DIALOG: $1"
    echo "$1" >> "$failureCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Finalise User Experience
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function finalise(){

    outputLineNumberInVerboseDebugMode

    if [[ "${configurationDownloadEstimation}" == "true" ]]; then

        outputLineNumberInVerboseDebugMode
        calculateFreeDiskSpace "FINALISE USER EXPERIENCE"

    fi

    if [[ "${jamfProPolicyTriggerFailure}" == "failed" ]]; then

        outputLineNumberInVerboseDebugMode
        updateScriptLog "Failed polcies detected …"
        if [[ -n "${webhookURL}" ]]; then
            updateScriptLog "Display Failure dialog: Sending webhook message"
            webhookStatus="Failures detected"
            webHookMessage
        fi

        if [[ "${failureDialog}" == "true" ]]; then

            outputLineNumberInVerboseDebugMode
            updateScriptLog "Display Failure dialog: ${failureDialog}"

            killProcess "caffeinate"
            if [[ "${brandingBannerDisplayText}" == "true" ]] ; then dialogUpdateSetupYourMac "title: Sorry ${loggedInUserFirstname}, something went sideways"; fi
            dialogUpdateSetupYourMac "icon: SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"
            dialogUpdateSetupYourMac "progresstext: Failures detected. Please click Continue for troubleshooting information."
            dialogUpdateSetupYourMac "button1text: Continue …"
            dialogUpdateSetupYourMac "button1: enable"
            dialogUpdateSetupYourMac "progress: reset"
            
            # Wait for user-acknowledgment due to detected failure
            wait

            dialogUpdateSetupYourMac "quit:"
            eval "${dialogFailureCMD}" & sleep 0.3

            updateScriptLog "\n\n# # #\n# FAILURE DIALOG\n# # #\n"
            updateScriptLog "Jamf Pro Policy Name Failures:"
            updateScriptLog "${jamfProPolicyNameFailures}"

            failureMessage="A failure has been detected, ${loggedInUserFirstname}. \n\nPlease complete the following steps:\n1. Reboot and login to your ${modelName}  \n2. Login to Self Service  \n3. Re-run any failed policy listed below  \n\nThe following failed:  \n${jamfProPolicyNameFailures}"
            
            if [[ -n "${supportTeamName}" ]]; then

                supportContactMessage+="If you need assistance, please contact the **${supportTeamName}**:  \n"

                if [[ -n "${supportTeamPhone}" ]]; then
                    supportContactMessage+="- **Telephone:** ${supportTeamPhone}\n"
                fi

                if [[ -n "${supportTeamEmail}" ]]; then
                    supportContactMessage+="- **Email:** $supportTeamEmail\n"
                fi

                if [[ -n "${supportTeamWebsite}" ]]; then
                    supportContactMessage+="- **Web**: ${supportTeamHyperlink}\n"
                fi

                if [[ -n "${supportKB}" ]]; then
                    supportContactMessage+="- **Knowledge Base Article:** $supportTeamErrorKB\n"
                fi
            
            fi

            failureMessage+="\n\n${supportContactMessage}"

            dialogUpdateFailure "message: ${failureMessage}"

            dialogUpdateFailure "icon: SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"
            dialogUpdateFailure "button1text: ${button1textCompletionActionOption}"

            # Wait for user-acknowledgment due to detected failure
            wait

            dialogUpdateFailure "quit:"
            quitScript "1"

        else

            outputLineNumberInVerboseDebugMode
            updateScriptLog "Display Failure dialog: ${failureDialog}"

            killProcess "caffeinate"
            if [[ "${brandingBannerDisplayText}" == "true" ]] ; then dialogUpdateSetupYourMac "title: Sorry ${loggedInUserFirstname}, something went sideways"; fi
            dialogUpdateSetupYourMac "icon: SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"
            dialogUpdateSetupYourMac "progresstext: Failures detected."
            dialogUpdateSetupYourMac "button1text: ${button1textCompletionActionOption}"
            dialogUpdateSetupYourMac "button1: enable"
            dialogUpdateSetupYourMac "progress: reset"
            dialogUpdateSetupYourMac "progresstext: Errors detected; please ${progressTextCompletionAction// and } your ${modelName}, ${loggedInUserFirstname}."

            quitScript "1"

        fi

    else

        outputLineNumberInVerboseDebugMode
        updateScriptLog "All polcies executed successfully"
        if [[ -n "${webhookURL}" ]]; then
            webhookStatus="Successful"
            updateScriptLog "Sending success webhook message"
            webHookMessage
        fi

        if [[ "${brandingBannerDisplayText}" == "true" ]] ; then dialogUpdateSetupYourMac "title: ${loggedInUserFirstname}‘s ${modelName} is ready!"; fi
        dialogUpdateSetupYourMac "icon: SF=checkmark.circle.fill,weight=bold,colour1=#00ff44,colour2=#075c1e"
        dialogUpdateSetupYourMac "progresstext: Complete! Please ${progressTextCompletionAction}enjoy your new ${modelName}, ${loggedInUserFirstname}!"
        dialogUpdateSetupYourMac "progress: complete"
        dialogUpdateSetupYourMac "button1text: ${button1textCompletionActionOption}"
        dialogUpdateSetupYourMac "button1: enable"

        quitScript "0"

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse JSON via osascript and JavaScript
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function get_json_value() {
    # set -x
    JSON="$1" osascript -l 'JavaScript' \
        -e 'const env = $.NSProcessInfo.processInfo.environment.objectForKey("JSON").js' \
        -e "JSON.parse(env).$2"
    # set +x
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse JSON via osascript and JavaScript for the Welcome dialog (thanks, @bartreardon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function get_json_value_welcomeDialog() {
    # set -x
    for var in "${@:2}"; do jsonkey="${jsonkey}['${var}']"; done
    JSON="$1" osascript -l 'JavaScript' \
        -e 'const env = $.NSProcessInfo.processInfo.environment.objectForKey("JSON").js' \
        -e "JSON.parse(env)$jsonkey"
    # set +x
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Execute Jamf Pro Policy Custom Events (thanks, @smithjw)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function run_jamf_trigger() {

    outputLineNumberInVerboseDebugMode

    trigger="$1"

    if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then

        updateScriptLog "SETUP YOUR MAC DIALOG: DEBUG MODE: TRIGGER: $jamfBinary policy -event $trigger ${suppressRecon}"
        sleep "${debugModeSleepAmount}"

    else

        updateScriptLog "SETUP YOUR MAC DIALOG: RUNNING: $jamfBinary policy -event $trigger"
        eval "${jamfBinary} policy -event ${trigger} ${suppressRecon}"                                     # Add comment for policy testing
        # eval "${jamfBinary} policy -event ${trigger} ${suppressRecon} -verbose | tee -a ${scriptLog}"    # Remove comment for policy testing

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm Policy Execution
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function confirmPolicyExecution() {

    outputLineNumberInVerboseDebugMode

    trigger="${1}"
    validation="${2}"
    updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution: '${trigger}' '${validation}'"
    if [ "${suppressReconOnPolicy}" == "true" ]; then suppressRecon="-forceNoRecon"; fi

    case ${validation} in

        */* ) # If the validation variable contains a forward slash (i.e., "/"), presume it's a path and check if that path exists on disk

            outputLineNumberInVerboseDebugMode
            if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
                updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution: DEBUG MODE: Skipping 'run_jamf_trigger ${trigger}'"
                sleep "${debugModeSleepAmount}"
            elif [[ -e "${validation}" ]]; then
                updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution: ${validation} exists; skipping 'run_jamf_trigger ${trigger}'"
                previouslyInstalled="true"
            else
                updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution: ${validation} does NOT exist; executing 'run_jamf_trigger ${trigger}'"
                previouslyInstalled="false"
                run_jamf_trigger "${trigger}"
            fi
            ;;

        "None" | "none" )

            outputLineNumberInVerboseDebugMode
            updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution: ${validation}"
            if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
                sleep "${debugModeSleepAmount}"
            else
                run_jamf_trigger "${trigger}"
            fi
            ;;

        "Recon" | "recon" )

            outputLineNumberInVerboseDebugMode
            updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution: ${validation}"
            if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
                updateScriptLog "SETUP YOUR MAC DIALOG: DEBUG MODE: Set 'debugMode' to false to update computer inventory with the following 'reconOptions': \"${reconOptions}\" …"
                sleep "${debugModeSleepAmount}"
            else
                updateScriptLog "SETUP YOUR MAC DIALOG: Updating computer inventory with the following 'reconOptions': \"${reconOptions}\" …"
                dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Updating …, "
                reconRaw=$( eval "${jamfBinary} recon ${reconOptions} -verbose | tee -a ${scriptLog}" )
                computerID=$( echo "${reconRaw}" | grep '<computer_id>' | xmllint --xpath xmllint --xpath '/computer_id/text()' - )
            fi
            ;;

        * )

            outputLineNumberInVerboseDebugMode
            updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution Catch-all: ${validation}"
            if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
                sleep "${debugModeSleepAmount}"
            else
                run_jamf_trigger "${trigger}"
            fi
            ;;

    esac

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate Policy Result
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function validatePolicyResult() {

    outputLineNumberInVerboseDebugMode

    trigger="${1}"
    validation="${2}"
    updateScriptLog "SETUP YOUR MAC DIALOG: Validate Policy Result: '${trigger}' '${validation}'"

    case ${validation} in

        ###
        # Absolute Path
        # Simulates pre-v1.6.0 behavior, for example: "/Applications/Microsoft Teams classic.app/Contents/Info.plist"
        ###

        */* ) 
            updateScriptLog "SETUP YOUR MAC DIALOG: Validate Policy Result: Testing for \"$validation\" …"
            if [[ "${previouslyInstalled}" == "true" ]]; then
                dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Previously Installed"
            elif [[ -e "${validation}" ]]; then
                dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Installed"
            else
                dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                jamfProPolicyTriggerFailure="failed"
                exitCode="1"
                jamfProPolicyNameFailures+="• $listitem  \n"
            fi
            ;;



        ###
        # Local
        # Validation within this script, for example: "rosetta" or "filevault"
        ###

        "Local" )
            case ${trigger} in
                rosetta ) 
                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Rosetta 2 … " # Thanks, @smithjw!
                    dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Checking …"
                    arch=$( /usr/bin/arch )
                    if [[ "${arch}" == "arm64" ]]; then
                        # Mac with Apple silicon; check for Rosetta
                        rosettaTest=$( arch -x86_64 /usr/bin/true 2> /dev/null ; echo $? )
                        if [[ "${rosettaTest}" -eq 0 ]]; then
                            # Installed
                            updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Rosetta 2 is installed"
                            dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Running"
                        else
                            # Not Installed
                            updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Rosetta 2 is NOT installed"
                            dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                            jamfProPolicyTriggerFailure="failed"
                            exitCode="1"
                            jamfProPolicyNameFailures+="• $listitem  \n"
                        fi
                    else
                        # Ineligible
                        updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Rosetta 2 is not applicable"
                        dialogUpdateSetupYourMac "listitem: index: $i, status: error, statustext: Ineligible"
                    fi
                    ;;
                filevault )
                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Validate FileVault … "
                    dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Checking …"
                    updateScriptLog "SETUP YOUR MAC DIALOG: Validate Policy Result: Pausing for 5 seconds for FileVault … "
                    sleep 5 # Arbitrary value; tuning needed
                    fileVaultCheck=$( fdesetup isactive )
                    if [[ -f /Library/Preferences/com.apple.fdesetup.plist ]] || [[ "$fileVaultCheck" == "true" ]]; then
                        fileVaultStatus=$( fdesetup status -extended -verbose 2>&1 )
                        case ${fileVaultStatus} in
                            *"FileVault is On."* ) 
                                updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: FileVault: FileVault is On."
                                dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Enabled"
                                ;;
                            *"Deferred enablement appears to be active for user"* )
                                updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: FileVault: Enabled"
                                dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Enabled (next login)"
                                ;;
                            *  )
                                dialogUpdateSetupYourMac "listitem: index: $i, status: error, statustext: Unknown"
                                jamfProPolicyTriggerFailure="failed"
                                exitCode="1"
                                jamfProPolicyNameFailures+="• $listitem  \n"
                                ;;
                        esac
                    else
                        updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: '/Library/Preferences/com.apple.fdesetup.plist' NOT Found"
                        dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                        jamfProPolicyTriggerFailure="failed"
                        exitCode="1"
                        jamfProPolicyNameFailures+="• $listitem  \n"
                    fi
                    ;;
                sophosEndpointServices )
                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Sophos Endpoint RTS Status … "
                    dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Checking …"
                    if [[ -d /Applications/Sophos/Sophos\ Endpoint.app ]]; then
                        if [[ -f /Library/Preferences/com.sophos.sav.plist ]]; then
                            sophosOnAccessRunning=$( /usr/bin/defaults read /Library/Preferences/com.sophos.sav.plist OnAccessRunning )
                            case ${sophosOnAccessRunning} in
                                "0" ) 
                                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Sophos Endpoint RTS Status: Disabled"
                                    dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                                    jamfProPolicyTriggerFailure="failed"
                                    exitCode="1"
                                    jamfProPolicyNameFailures+="• $listitem  \n"
                                    ;;
                                "1" )
                                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Sophos Endpoint RTS Status: Enabled"
                                    dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Running"
                                    ;;
                                *  )
                                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Sophos Endpoint RTS Status: Unknown"
                                    dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Unknown"
                                    jamfProPolicyTriggerFailure="failed"
                                    exitCode="1"
                                    jamfProPolicyNameFailures+="• $listitem  \n"
                                    ;;
                            esac
                        else
                            updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Sophos Endpoint Not Found"
                            dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                            jamfProPolicyTriggerFailure="failed"
                            exitCode="1"
                            jamfProPolicyNameFailures+="• $listitem  \n"
                        fi
                    else
                        dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                        jamfProPolicyTriggerFailure="failed"
                        exitCode="1"
                        jamfProPolicyNameFailures+="• $listitem  \n"
                    fi
                    ;;
                globalProtect )
                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Palo Alto Networks GlobalProtect Status … "
                    dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Checking …"
                    if [[ -d /Applications/GlobalProtect.app ]]; then
                        updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Pausing for 10 seconds to allow Palo Alto Networks GlobalProtect Services … "
                        sleep 10 # Arbitrary value; tuning needed
                        if [[ -f /Library/Preferences/com.paloaltonetworks.GlobalProtect.settings.plist ]]; then
                            globalProtectStatus=$( /usr/libexec/PlistBuddy -c "print :Palo\ Alto\ Networks:GlobalProtect:PanGPS:disable-globalprotect" /Library/Preferences/com.paloaltonetworks.GlobalProtect.settings.plist )
                            case "${globalProtectStatus}" in
                                "0" )
                                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Palo Alto Networks GlobalProtect Status: Enabled"
                                    dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Running"
                                    ;;
                                "1" )
                                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Palo Alto Networks GlobalProtect Status: Disabled"
                                    dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                                    jamfProPolicyTriggerFailure="failed"
                                    exitCode="1"
                                    jamfProPolicyNameFailures+="• $listitem  \n"
                                    ;;
                                *  )
                                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Palo Alto Networks GlobalProtect Status: Unknown"
                                    dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Unknown"
                                    jamfProPolicyTriggerFailure="failed"
                                    exitCode="1"
                                    jamfProPolicyNameFailures+="• $listitem  \n"
                                    ;;
                            esac
                        else
                            updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Palo Alto Networks GlobalProtect Not Found"
                            dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                            jamfProPolicyTriggerFailure="failed"
                            exitCode="1"
                            jamfProPolicyNameFailures+="• $listitem  \n"
                        fi
                    else
                        dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                        jamfProPolicyTriggerFailure="failed"
                        exitCode="1"
                        jamfProPolicyNameFailures+="• $listitem  \n"
                    fi
                    ;;
                * )
                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Local Validation “${validation}” Missing"
                    dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Missing Local “${validation}” Validation"
                    jamfProPolicyTriggerFailure="failed"
                    exitCode="1"
                    jamfProPolicyNameFailures+="• $listitem  \n"
                    ;;
            esac
            ;;



        ###
        # Remote
        # Validation via a Jamf Pro policy which has a single-script payload, for example: "symvGlobalProtect"
        # See: https://vimeo.com/782561166
        ###

        "Remote" )
            if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
                updateScriptLog "SETUP YOUR MAC DIALOG: DEBUG MODE: Remotely Confirm Policy Execution: Skipping 'run_jamf_trigger ${trigger}'"
                dialogUpdateSetupYourMac "listitem: index: $i, status: error, statustext: Debug Mode Enabled"
                sleep 0.5
            else
                updateScriptLog "SETUP YOUR MAC DIALOG: Remotely Validate '${trigger}' '${validation}'"
                dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Checking …"
                result=$( "${jamfBinary}" policy -event "${trigger}" | grep "Script result:" )
                if [[ "${result}" == *"Running"* ]]; then
                    dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Running"
                elif [[ "${result}" == *"Installed"* || "${result}" == *"Success"*  ]]; then
                    dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Installed"
                else
                    dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                    jamfProPolicyTriggerFailure="failed"
                    exitCode="1"
                    jamfProPolicyNameFailures+="• $listitem  \n"
                fi
            fi
            ;;



        ###
        # None: For triggers which don't require validation
        # (Always evaluates as: 'success' and 'Installed')
        ###

        "None" | "none")

            outputLineNumberInVerboseDebugMode
            updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution: ${validation}"
            dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Installed"
            ;;



        ###
        # Recon: For reporting computer inventory update
        # (Always evaluates as: 'success' and 'Updated')
        ###

        "Recon" | "recon" )

            outputLineNumberInVerboseDebugMode
            updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution: ${validation}"
            dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Updated"
            ;;



        ###
        # Catch-all
        ###

        * )

            outputLineNumberInVerboseDebugMode
            updateScriptLog "SETUP YOUR MAC DIALOG: Validate Policy Results Catch-all: ${validation}"
            dialogUpdateSetupYourMac "listitem: index: $i, status: error, statustext: Error"
            ;;

    esac

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Kill a specified process (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function killProcess() {
    process="$1"
    if process_pid=$( pgrep -a "${process}" 2>/dev/null ) ; then
        updateScriptLog "Attempting to terminate the '$process' process …"
        updateScriptLog "(Termination message indicates success.)"
        kill "$process_pid" 2> /dev/null
        if pgrep -a "$process" >/dev/null ; then
            updateScriptLog "ERROR: '$process' could not be terminated."
        fi
    else
        updateScriptLog "The '$process' process isn't running."
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Completion Action (i.e., Wait, Sleep, Logout, Restart or Shutdown)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function completionAction() {

    outputLineNumberInVerboseDebugMode

    if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then

        # If Debug Mode is enabled, ignore specified `completionActionOption`, display simple dialog box and exit
        runAsUser osascript -e 'display dialog "Setup Your Mac is operating in Debug Mode.\r\r• completionActionOption == '"'${completionActionOption}'"'\r\r" with title "Setup Your Mac: Debug Mode" buttons {"Close"} with icon note'
        exitCode="0"

    else

        shopt -s nocasematch

        case ${completionActionOption} in

            "Shut Down" )
                updateScriptLog "COMPLETION ACTION: Shut Down sans user interaction"
                killProcess "Self Service"
                # runAsUser osascript -e 'tell app "System Events" to shut down'
                # sleep 5 && runAsUser osascript -e 'tell app "System Events" to shut down' &
                sleep 5 && shutdown -h now &
                ;;

            "Shut Down Attended" )
                updateScriptLog "COMPLETION ACTION: Shut Down, requiring user-interaction"
                killProcess "Self Service"
                wait
                # runAsUser osascript -e 'tell app "System Events" to shut down'
                # sleep 5 && runAsUser osascript -e 'tell app "System Events" to shut down' &
                sleep 5 && shutdown -h now &
                ;;

            "Shut Down Confirm" )
                updateScriptLog "COMPLETION ACTION: Shut down, only after macOS time-out or user confirmation"
                runAsUser osascript -e 'tell app "loginwindow" to «event aevtrsdn»'
                ;;

            "Restart" )
                updateScriptLog "COMPLETION ACTION: Restart sans user interaction"
                killProcess "Self Service"
                # runAsUser osascript -e 'tell app "System Events" to restart'
                # sleep 5 && runAsUser osascript -e 'tell app "System Events" to restart' &
                sleep 5 && shutdown -r now &
                ;;

            "Restart Attended" )
                updateScriptLog "COMPLETION ACTION: Restart, requiring user-interaction"
                killProcess "Self Service"
                wait
                # runAsUser osascript -e 'tell app "System Events" to restart'
                # sleep 5 && runAsUser osascript -e 'tell app "System Events" to restart' &
                sleep 5 && shutdown -r now &
                ;;

            "Restart Confirm" )
                updateScriptLog "COMPLETION ACTION: Restart, only after macOS time-out or user confirmation"
                runAsUser osascript -e 'tell app "loginwindow" to «event aevtrrst»'
                ;;

            "Log Out" )
                updateScriptLog "COMPLETION ACTION: Log out sans user interaction"
                killProcess "Self Service"
                # sleep 5 && runAsUser osascript -e 'tell app "loginwindow" to «event aevtrlgo»'
                # sleep 5 && runAsUser osascript -e 'tell app "loginwindow" to «event aevtrlgo»' &
                sleep 5 && launchctl bootout user/"${loggedInUserID}"
                ;;

            "Log Out Attended" )
                updateScriptLog "COMPLETION ACTION: Log out sans user interaction"
                killProcess "Self Service"
                wait
                # sleep 5 && runAsUser osascript -e 'tell app "loginwindow" to «event aevtrlgo»'
                # sleep 5 && runAsUser osascript -e 'tell app "loginwindow" to «event aevtrlgo»' &
                sleep 5 && launchctl bootout user/"${loggedInUserID}"
                ;;

            "Log Out Confirm" )
                updateScriptLog "COMPLETION ACTION: Log out, only after macOS time-out or user confirmation"
                sleep 5 && runAsUser osascript -e 'tell app "System Events" to log out'
                ;;

            "Sleep"* )
                sleepDuration=$( awk '{print $NF}' <<< "${1}" )
                updateScriptLog "COMPLETION ACTION: Sleeping for ${sleepDuration} seconds …"
                sleep "${sleepDuration}"
                killProcess "Dialog"
                updateScriptLog "Goodnight!"
                ;;

            "Wait" )
                updateScriptLog "COMPLETION ACTION: Waiting for user interaction …"
                wait
                ;;

            "Quit" )
                updateScriptLog "COMPLETION ACTION: Quitting script"
                exitCode="0"
                ;;

            * )
                updateScriptLog "COMPLETION ACTION: Using the default of 'wait'"
                wait
                ;;

        esac

        shopt -u nocasematch

    fi

    # Remove custom welcomeBannerImageFileName
    if [[ -e "/var/tmp/${welcomeBannerImageFileName}" ]]; then
        updateScriptLog "COMPLETION ACTION: Removing /var/tmp/${welcomeBannerImageFileName} …"
        rm "/var/tmp/${welcomeBannerImageFileName}"
    fi

    # Remove overlayicon
    if [[ -e ${overlayicon} ]]; then
        updateScriptLog "COMPLETION ACTION: Removing ${overlayicon} …"
        rm "${overlayicon}"
    fi

    exit "${exitCode}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Welcome dialog 'infobox' animation (thanks, @bartreadon!)
# To convert emojis, see: https://r12a.github.io/app-conversion/
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function welcomeDialogInfoboxAnimation() {
    callingPID=$1
    # clock_emojis=("🕐" "🕑" "🕒" "🕓" "🕔" "🕕" "🕖" "🕗" "🕘" "🕙" "🕚" "🕛")
    clock_emojis=("&#128336;" "&#128337;" "&#128338;" "&#128339;" "&#128340;" "&#128341;" "&#128342;" "&#128343;" "&#128344;" "&#128345;" "&#128346;" "&#128347;")
    while true; do
        for emoji in "${clock_emojis[@]}"; do
            if kill -0 "$callingPID" 2>/dev/null; then
                dialogUpdateWelcome "infobox: Testing Connection $emoji"
            else
                break
            fi
            sleep 0.6
        done
    done
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Setup Your Mac dialog 'infobox' animation (thanks, @bartreadon!)
# To convert emojis, see: https://r12a.github.io/app-conversion/
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function setupYourMacDialogInfoboxAnimation() {
    callingPID=$1
    # clock_emojis=("🕐" "🕑" "🕒" "🕓" "🕔" "🕕" "🕖" "🕗" "🕘" "🕙" "🕚" "🕛")
    clock_emojis=("&#128336;" "&#128337;" "&#128338;" "&#128339;" "&#128340;" "&#128341;" "&#128342;" "&#128343;" "&#128344;" "&#128345;" "&#128346;" "&#128347;")
    while true; do
        for emoji in "${clock_emojis[@]}"; do
            if kill -0 "$callingPID" 2>/dev/null; then
                dialogUpdateSetupYourMac "infobox: Testing Connection $emoji"
            else
                break
            fi
            sleep 0.6
        done
    done
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check Network Quality for Configurations (thanks, @bartreadon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function checkNetworkQualityConfigurations() {
    
    myPID="$$"
    updateScriptLog "WELCOME DIALOG: Display Welcome dialog 'infobox' animation …"
    welcomeDialogInfoboxAnimation "$myPID" &
    welcomeDialogInfoboxAnimationPID="$!"

    networkQuality -s -v -c > /var/tmp/networkQualityTest
    kill ${welcomeDialogInfoboxAnimationPID}
    outputLineNumberInVerboseDebugMode

    updateScriptLog "WELCOME DIALOG: Completed networkQualityTest …"
    networkQualityTest=$( < /var/tmp/networkQualityTest )
    rm /var/tmp/networkQualityTest

    case "${osVersion}" in

        11* ) 
            dlThroughput="N/A; macOS ${osVersion}"
            dlResponsiveness="N/A; macOS ${osVersion}"
            dlStartDate="N/A; macOS ${osVersion}"
            dlEndDate="N/A; macOS ${osVersion}"
            ;;

        12* | 13* | 14*)
            dlThroughput=$( get_json_value "$networkQualityTest" "dl_throughput")
            dlResponsiveness=$( get_json_value "$networkQualityTest" "dl_responsiveness" )
            dlStartDate=$( get_json_value "$networkQualityTest" "start_date" )
            dlEndDate=$( get_json_value "$networkQualityTest" "end_date" )
            ;;

    esac

    mbps=$( echo "scale=2; ( $dlThroughput / 1000000 )" | bc )
    updateScriptLog "WELCOME DIALOG: $mbps (Mbps)"

    configurationOneEstimatedSeconds=$( echo "scale=2; ((((( $configurationOneSize / $mbps ) * 60 ) * 60 ) * $correctionCoefficient ) + $configurationOneInstallBuffer)" | bc | sed 's/\.[0-9]*//' )
    updateScriptLog "WELCOME DIALOG: Configuration One Estimated Seconds: $configurationOneEstimatedSeconds"
    updateScriptLog "WELCOME DIALOG: Configuration One Estimate: $(printf '%dh:%dm:%ds\n' $((configurationOneEstimatedSeconds/3600)) $((configurationOneEstimatedSeconds%3600/60)) $((configurationOneEstimatedSeconds%60)))"

    configurationTwoEstimatedSeconds=$( echo "scale=2; ((((( $configurationTwoSize / $mbps ) * 60 ) * 60 ) * $correctionCoefficient ) + $configurationTwoInstallBuffer)" | bc | sed 's/\.[0-9]*//' )
    updateScriptLog "WELCOME DIALOG: Configuration Two Estimated Seconds: $configurationTwoEstimatedSeconds"
    updateScriptLog "WELCOME DIALOG: Configuration Two Estimate: $(printf '%dh:%dm:%ds\n' $((configurationTwoEstimatedSeconds/3600)) $((configurationTwoEstimatedSeconds%3600/60)) $((configurationTwoEstimatedSeconds%60)))"

    configurationThreeEstimatedSeconds=$( echo "scale=2; ((((( $configurationThreeSize / $mbps ) * 60 ) * 60 ) * $correctionCoefficient ) + $configurationThreeInstallBuffer)" | bc | sed 's/\.[0-9]*//' )
    updateScriptLog "WELCOME DIALOG: Configuration Three Estimated Seconds: $configurationThreeEstimatedSeconds"
    updateScriptLog "WELCOME DIALOG: Configuration Three Estimate: $(printf '%dh:%dm:%ds\n' $((configurationThreeEstimatedSeconds/3600)) $((configurationThreeEstimatedSeconds%3600/60)) $((configurationThreeEstimatedSeconds%60)))"

    updateScriptLog "WELCOME DIALOG: Network Quality Test: Started: $dlStartDate, Ended: $dlEndDate; Download: $mbps Mbps, Responsiveness: $dlResponsiveness"
    dialogUpdateWelcome "infobox: **Connection:**  \n- Download:  \n$mbps Mbps  \n\n**Estimates:**  \n- ${configurationOneName}:  \n$(printf '%dh:%dm:%ds\n' $((configurationOneEstimatedSeconds/3600)) $((configurationOneEstimatedSeconds%3600/60)) $((configurationOneEstimatedSeconds%60)))  \n\n- ${configurationTwoName}:  \n$(printf '%dh:%dm:%ds\n' $((configurationTwoEstimatedSeconds/3600)) $((configurationTwoEstimatedSeconds%3600/60)) $((configurationTwoEstimatedSeconds%60)))  \n\n- ${configurationThreeName}:  \n$(printf '%dh:%dm:%ds\n' $((configurationThreeEstimatedSeconds/3600)) $((configurationThreeEstimatedSeconds%3600/60)) $((configurationThreeEstimatedSeconds%60)))"

    # If option to lock the continue button is set to true, enable the continue button now to let the user progress
    if [[ "${lockContinueBeforeEstimations}" == "true" ]]; then
        updateScriptLog "WELCOME DIALOG: Enabling Continue Button"
        dialogUpdateWelcome "button1: enable"
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check Network Quality for Catch-all Configuration (thanks, @bartreadon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function checkNetworkQualityCatchAllConfiguration() {
    
    myPID="$$"
    updateScriptLog "SETUP YOUR MAC DIALOG: Display Welcome dialog 'infobox' animation …"
    setupYourMacDialogInfoboxAnimation "$myPID" &
    setupYourMacDialogInfoboxAnimationPID="$!"

    networkQuality -s -v -c > /var/tmp/networkQualityTest
    kill ${setupYourMacDialogInfoboxAnimationPID}
    outputLineNumberInVerboseDebugMode

    updateScriptLog "SETUP YOUR MAC DIALOG: Completed networkQualityTest …"
    networkQualityTest=$( < /var/tmp/networkQualityTest )
    rm /var/tmp/networkQualityTest

    case "${osVersion}" in

        11* ) 
            dlThroughput="N/A; macOS ${osVersion}"
            dlResponsiveness="N/A; macOS ${osVersion}"
            dlStartDate="N/A; macOS ${osVersion}"
            dlEndDate="N/A; macOS ${osVersion}"
            ;;

        12* | 13* | 14*)
            dlThroughput=$( get_json_value "$networkQualityTest" "dl_throughput")
            dlResponsiveness=$( get_json_value "$networkQualityTest" "dl_responsiveness" )
            dlStartDate=$( get_json_value "$networkQualityTest" "start_date" )
            dlEndDate=$( get_json_value "$networkQualityTest" "end_date" )
            ;;

    esac

    mbps=$( echo "scale=2; ( $dlThroughput / 1000000 )" | bc )
    updateScriptLog "SETUP YOUR MAC DIALOG: $mbps (Mbps)"

    configurationCatchAllEstimatedSeconds=$( echo "scale=2; ((((( $configurationCatchAllSize / $mbps ) * 60 ) * 60 ) * $correctionCoefficient ) + $configurationCatchAllInstallBuffer)" | bc | sed 's/\.[0-9]*//' )
    updateScriptLog "SETUP YOUR MAC DIALOG: Catch-all Configuration Estimated Seconds: $configurationCatchAllEstimatedSeconds"
    updateScriptLog "SETUP YOUR MAC DIALOG: Catch-all Configuration Estimate: $(printf '%dh:%dm:%ds\n' $((configurationCatchAllEstimatedSeconds/3600)) $((configurationCatchAllEstimatedSeconds%3600/60)) $((configurationCatchAllEstimatedSeconds%60)))"

    updateScriptLog "SETUP YOUR MAC DIALOG: Network Quality Test: Started: $dlStartDate, Ended: $dlEndDate; Download: $mbps Mbps, Responsiveness: $dlResponsiveness"
    dialogUpdateSetupYourMac "infobox: **Connection:**  \n- Download:  \n$mbps Mbps  \n\n**Estimates:**  \n- $(printf '%dh:%dm:%ds\n' $((configurationCatchAllEstimatedSeconds/3600)) $((configurationCatchAllEstimatedSeconds%3600/60)) $((configurationCatchAllEstimatedSeconds%60)))"
    if [[ "${lockContinueBeforeEstimations}" == "true" ]]; then
        updateScriptLog "WELCOME DIALOG: Enabling Continue Button"
        dialogUpdateWelcome "button1: enable"
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Webhook Message (Microsoft Teams or Slack) (thanks, @robjschroeder! and @iDrewbs!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function webHookMessage() {

    outputLineNumberInVerboseDebugMode

    jamfProURL=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)

    # # Jamf Pro URL for on-prem, multi-node, clustered environments
    # case ${jamfProURL} in
    #     *"beta"*    ) jamfProURL="https://jamfpro-beta.internal.company.com/" ;;
    #     *           ) jamfProURL="https://jamfpro-prod.internal.company.com/" ;;
    # esac

    jamfProComputerURL="${jamfProURL}computers.html?id=${computerID}&o=r"

    # If there aren't any failures, use "None" for the value of `jamfProPolicyNameFailures`
    if [[ -z "${jamfProPolicyNameFailures}" ]]; then
        jamfProPolicyNameFailures="None"
    fi

    if [[ $webhookURL == *"slack"* ]]; then
        
        updateScriptLog "Generating Slack Message …"
        
        webHookdata=$(cat <<EOF
        {
            "blocks": [
                {
                    "type": "header",
                    "text": {
                        "type": "plain_text",
                        "text": "New Mac Enrollment: '${webhookStatus}'",
                        "emoji": true
                    }
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": "*Computer Name:*\n$( scutil --get ComputerName )"
                        },
                        {
                            "type": "mrkdwn",
                            "text": "*Serial:*\n${serialNumber}"
                        },
                        {
                            "type": "mrkdwn",
                            "text": "*Timestamp:*\n${timestamp}"
                        },
                        {
                            "type": "mrkdwn",
                            "text": "*Configuration:*\n${symConfiguration}"
                        },
                        {
                            "type": "mrkdwn",
                            "text": "*User:*\n${loggedInUser}"
                        },
                        {
                            "type": "mrkdwn",
                            "text": "*OS Version:*\n${osVersion} (${osBuild})"
                        },
                        {
                            "type": "mrkdwn",
                            "text": "*Additional Comments:*\n${jamfProPolicyNameFailures}"
                        }
                    ]
                },
                {
                    "type": "actions",
                    "elements": [
                        {
                            "type": "button",
                            "text": {
                                "type": "plain_text",
                                "text": "View in Jamf Pro"
                                },
                            "style": "primary",
                            "url": "${jamfProComputerURL}"
                        }
                    ]
                }
            ]
        }
EOF
)

        # Send the message to Slack
        updateScriptLog "Send the message to Slack …"
        updateScriptLog "${webHookdata}"
        
        # Submit the data to Slack
        /usr/bin/curl -sSX POST -H 'Content-type: application/json' --data "${webHookdata}" $webhookURL 2>&1
        
        webhookResult="$?"
        updateScriptLog "Slack Webhook Result: ${webhookResult}"
        
    else
        
        updateScriptLog "Generating Microsoft Teams Message …"

        # URL to an image to add to your notification
        activityImage="https://creazilla-store.fra1.digitaloceanspaces.com/cliparts/78010/old-mac-computer-clipart-md.png"

        webHookdata=$(cat <<EOF
{
    "@type": "MessageCard",
    "@context": "http://schema.org/extensions",
    "themeColor": "E4002B",
    "summary": "New Mac Enrollment: '${webhookStatus}'",
    "sections": [{
        "activityTitle": "New Mac Enrollment: ${webhookStatus}",
        "activitySubtitle": "${jamfProURL}",
        "activityImage": "${activityImage}",
        "facts": [{
            "name": "Mac Serial",
            "value": "${serialNumber}"
        }, {
            "name": "Computer Name",
            "value": "$( scutil --get ComputerName )"
        }, {
            "name": "Timestamp",
            "value": "${timestamp}"
        }, {
            "name": "Configuration",
            "value": "${symConfiguration}"
        }, {
            "name": "User",
            "value": "${loggedInUser}"
        }, {
            "name": "Operating System Version",
            "value": "${osVersion} (${osBuild})"
        }, {
            "name": "Additional Comments",
            "value": "${jamfProPolicyNameFailures}"
}],
        "markdown": true,
        "potentialAction": [{
        "@type": "OpenUri",
        "name": "View in Jamf Pro",
        "targets": [{
        "os": "default",
            "uri": "${jamfProComputerURL}"
            }]
        }]
    }]
}
EOF
)

    # Send the message to Microsoft Teams
    updateScriptLog "Send the message Microsoft Teams …"
    updateScriptLog "${webHookdata}"

    curl --request POST \
    --url "${webhookURL}" \
    --header 'Content-Type: application/json' \
    --data "${webHookdata}"
    
    webhookResult="$?"
    updateScriptLog "Microsoft Teams Webhook Result: ${webhookResult}"
    
    fi
    
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit Script (thanks, @bartreadon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function quitScript() {

    outputLineNumberInVerboseDebugMode

    updateScriptLog "QUIT SCRIPT: Exiting …"

    # Stop `caffeinate` process
    updateScriptLog "QUIT SCRIPT: De-caffeinate …"
    killProcess "caffeinate"

    # Toggle `jamf` binary check-in 
    if [[ "${completionActionOption}" == "Log Out"* ]] || [[ "${completionActionOption}" == "Sleep"* ]] || [[ "${completionActionOption}" == "Quit" ]] || [[ "${completionActionOption}" == "wait" ]] ; then
        toggleJamfLaunchDaemon
    fi
    
    # Remove welcomeCommandFile
    if [[ -e ${welcomeCommandFile} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${welcomeCommandFile} …"
        rm "${welcomeCommandFile}"
    fi

    # Remove welcomeJSONFile
    if [[ -e ${welcomeJSONFile} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${welcomeJSONFile} …"
        rm "${welcomeJSONFile}"
    fi

    # Remove setupYourMacCommandFile
    if [[ -e ${setupYourMacCommandFile} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${setupYourMacCommandFile} …"
        rm "${setupYourMacCommandFile}"
    fi

    # Remove failureCommandFile
    if [[ -e ${failureCommandFile} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${failureCommandFile} …"
        rm "${failureCommandFile}"
    fi

    # Remove any default dialog file
    if [[ -e /var/tmp/dialog.log ]]; then
        updateScriptLog "QUIT SCRIPT: Removing default dialog file …"
        rm /var/tmp/dialog.log
    fi

    # Check for user clicking "Quit" at Welcome dialog
    if [[ "${welcomeReturnCode}" == "2" ]]; then
        
        # Remove custom welcomeBannerImageFileName
        if [[ -e "/var/tmp/${welcomeBannerImageFileName}" ]]; then
            updateScriptLog "COMPLETION ACTION: Removing /var/tmp/${welcomeBannerImageFileName} …"
            rm "/var/tmp/${welcomeBannerImageFileName}"
        fi

        # Remove overlayicon
        if [[ -e ${overlayicon} ]]; then
            updateScriptLog "COMPLETION ACTION: Removing ${overlayicon} …"
            rm "${overlayicon}"
        fi
        
        exitCode="1"
        exit "${exitCode}"
    
    else
    
        updateScriptLog "QUIT SCRIPT: Executing Completion Action Option: '${completionActionOption}' …"
        completionAction "${completionActionOption}"
    
    fi

}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Debug Mode Logging Notification
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
    updateScriptLog "\n\n###\n# ${scriptVersion}\n###\n"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# If Debug Mode is enabled, replace `blurscreen` with `movable`
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] || [[ "${moveableInProduction}" == "true" ]] ; then
    welcomeJSON=${welcomeJSON//blurscreen/moveable}
    dialogSetupYourMacCMD=${dialogSetupYourMacCMD//blurscreen/moveable}
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Welcome dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${welcomeDialog}" == "video" ]]; then

    updateScriptLog "WELCOME DIALOG: Displaying ${welcomeVideoID} …"
    eval "${dialogBinary} --args ${welcomeVideo}"

    outputLineNumberInVerboseDebugMode
    if [[ -n "${presetConfiguration}" ]]; then
        symConfiguration="${presetConfiguration}"
    else
        symConfiguration="Catch-all (video)"
    fi
    updateScriptLog "WELCOME DIALOG: Using ${symConfiguration} Configuration …"
    policyJSONConfiguration

    eval "${dialogSetupYourMacCMD[*]}" & sleep 0.3
    dialogUpdateSetupYourMac "activate:"
    if [[ -n "${overlayoverride}" ]]; then
        dialogUpdateSetupYourMac "overlayicon: ${overlayoverride}"
    fi

elif [[ "${welcomeDialog}" == "messageOnly" ]]; then

    outputLineNumberInVerboseDebugMode

    updateScriptLog "WELCOME DIALOG: Displaying ${welcomeDialog} …"

    # Construct `welcomeJSON`, sans `textfield` and `selectitems`
    welcomeJSON='
    {
        "commandfile" : "'"${welcomeCommandFile}"'",
        "bannerimage" : "'"${welcomeBannerImage}"'",
        "bannertext" : "'"${welcomeBannerText}"'",
        "title" : "'"${welcomeTitle}"'",
        "message" : "'"${welcomeMessage}"'",
        "icon" : "'"${welcomeIcon}"'",
        "infobox" : "",
        "iconsize" : "198.0",
        "button1text" : "Continue",
        "timer" : "60",
        "infotext" : "'"${scriptVersion}"'",
        "blurscreen" : "true",
        "ontop" : "true",
        "titlefont" : "shadow=true, size=36, colour=#FFFDF4",
        "messagefont" : "size=14",
        "height" : "800"
    }
    '

    # Write Welcome JSON to disk
    echo "$welcomeJSON" > "$welcomeJSONFile"

    # Display Welcome dialog
    eval "${dialogBinary} --jsonfile ${welcomeJSONFile} --json"

    # Set Configuration
    if [[ -n "${presetConfiguration}" ]]; then
        symConfiguration="${presetConfiguration}"
    else
        symConfiguration="Catch-all (messageOnly)"
    fi
    updateScriptLog "WELCOME DIALOG: Using ${symConfiguration} Configuration …"
    policyJSONConfiguration

    # Display main SYM dialog
    eval "${dialogSetupYourMacCMD[*]}" & sleep 0.3
    dialogUpdateSetupYourMac "activate:"
    if [[ -n "${overlayoverride}" ]]; then
        dialogUpdateSetupYourMac "overlayicon: ${overlayoverride}"
    fi

elif [[ "${welcomeDialog}" == "userInput" ]]; then

    outputLineNumberInVerboseDebugMode

    # Estimate Configuration Download Times
    if [[ "${configurationDownloadEstimation}" == "true" ]] && [[ "${promptForConfiguration}" == "true" ]]; then

        outputLineNumberInVerboseDebugMode

        calculateFreeDiskSpace "WELCOME DIALOG"

        updateScriptLog "WELCOME DIALOG: Starting checkNetworkQualityConfigurations …"
        checkNetworkQualityConfigurations &

        updateScriptLog "WELCOME DIALOG: Write 'welcomeJSON' to $welcomeJSONFile …"
        echo "$welcomeJSON" > "$welcomeJSONFile"

        # If option to lock the continue button is set to true, open welcome dialog with button 1 disabled
        if [[ "${lockContinueBeforeEstimations}" == "true" ]]; then
            
            updateScriptLog "WELCOME DIALOG: Display 'Welcome' dialog with disabled Continue Button …"
            welcomeResults=$( eval "${dialogBinary} --jsonfile ${welcomeJSONFile} --json --button1disabled" )
            
        else

            updateScriptLog "WELCOME DIALOG: Display 'Welcome' dialog …"
            welcomeResults=$( eval "${dialogBinary} --jsonfile ${welcomeJSONFile} --json" )

        fi

    else

        # Display Welcome dialog, sans estimation of Configuration download times
        updateScriptLog "WELCOME DIALOG: Skipping estimation of Configuration download times"
        
        # Write Welcome JSON to disk
        welcomeJSON=${welcomeJSON//Analyzing …/}
        echo "$welcomeJSON" > "$welcomeJSONFile"
        welcomeResults=$( eval "${dialogBinary} --jsonfile ${welcomeJSONFile} --json" )

    fi

    # Evaluate User Input
    if [[ -z "${welcomeResults}" ]]; then
        welcomeReturnCode="2"
    else
        welcomeReturnCode="0"
    fi

    case "${welcomeReturnCode}" in

        0)  # Process exit code 0 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} entered information and clicked Continue"

            ###
            # Extract the various values from the welcomeResults JSON
            ###

            computerName=$(get_json_value_welcomeDialog "$welcomeResults" "Computer Name")
            userName=$(get_json_value_welcomeDialog "$welcomeResults" "User Name")
            realName=$(get_json_value_welcomeDialog "$welcomeResults" "Full Name")
            email=$(get_json_value_welcomeDialog "$welcomeResults" "E-mail")
            assetTag=$(get_json_value_welcomeDialog "$welcomeResults" "Asset Tag")
            symConfiguration=$(get_json_value_welcomeDialog "$welcomeResults" "Configuration" "selectedValue")
            if [ -n "$presetConfiguration" ]; then symConfiguration="${presetConfiguration}"; fi
            department=$(get_json_value_welcomeDialog "$welcomeResults" "Department" "selectedValue" | grep -v "Please select your department" )
            room=$(get_json_value_welcomeDialog "$welcomeResults" "Room")
            building=$(get_json_value_welcomeDialog "$welcomeResults" "Building" "selectedValue" | grep -v "Please select your building" )
            
            if [ -n "${positionListRaw}" ]; then
                position=$(get_json_value_welcomeDialog "$welcomeResults" "Position" "selectedValue" )
            else
                position=$(get_json_value_welcomeDialog "$welcomeResults" "Position")
            fi



            ###
            # Output the various values from the welcomeResults JSON to the log file
            ###

            updateScriptLog "WELCOME DIALOG: • Computer Name: $computerName"
            updateScriptLog "WELCOME DIALOG: • User Name: $userName"
            updateScriptLog "WELCOME DIALOG: • Real Name: $realName"
            updateScriptLog "WELCOME DIALOG: • E-mail: $email"
            updateScriptLog "WELCOME DIALOG: • Asset Tag: $assetTag"
            updateScriptLog "WELCOME DIALOG: • Configuration: $symConfiguration"
            updateScriptLog "WELCOME DIALOG: • Department: $department"
            updateScriptLog "WELCOME DIALOG: • Building: $building"
            updateScriptLog "WELCOME DIALOG: • Room: $room"
            updateScriptLog "WELCOME DIALOG: • Position: $position"


            ###
            # Select `policyJSON` based on selected Configuration
            ###

            policyJSONConfiguration



            ###
            # Evaluate Various User Input
            ###

            # Computer Name
            if [[ -n "${computerName}" ]]; then

                # UNTESTED, UNSUPPORTED "YOYO" EXAMPLE
                updateScriptLog "WELCOME DIALOG: Set Computer Name …"
                currentComputerName=$( scutil --get ComputerName )
                currentLocalHostName=$( scutil --get LocalHostName )

                # Sets LocalHostName to a maximum of 15 characters, comprised of first eight characters of the computer's
                # serial number and the last six characters of the client's MAC address
                firstEightSerialNumber=$( system_profiler SPHardwareDataType | awk '/Serial\ Number\ \(system\)/ {print $NF}' | cut -c 1-8 )
                lastSixMAC=$( ifconfig en0 | awk '/ether/ {print $2}' | sed 's/://g' | cut -c 7-12 )
                newLocalHostName=${firstEightSerialNumber}-${lastSixMAC}

                if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then

                    updateScriptLog "WELCOME DIALOG: DEBUG MODE: Would have renamed computer from: \"${currentComputerName}\" to \"${computerName}\" "
                    updateScriptLog "WELCOME DIALOG: DEBUG MODE: Would have renamed LocalHostName from: \"${currentLocalHostName}\" to \"${newLocalHostName}\" "

                else

                    # Set the Computer Name to the user-entered value
                    scutil --set ComputerName "${computerName}"

                    # Set the LocalHostName to `newLocalHostName`
                    scutil --set LocalHostName "${newLocalHostName}"

                    # Delay required to reflect change …
                    # … side-effect is a delay in the "Setup Your Mac" dialog appearing
                    sleep 5
                    updateScriptLog "WELCOME DIALOG: Renamed computer from: \"${currentComputerName}\" to \"$( scutil --get ComputerName )\" "
                    updateScriptLog "WELCOME DIALOG: Renamed LocalHostName from: \"${currentLocalHostName}\" to \"$( scutil --get LocalHostName )\" "

                fi

            else

                updateScriptLog "WELCOME DIALOG: ${loggedInUser} did NOT specify a new computer name"
                updateScriptLog "WELCOME DIALOG: • Current Computer Name: \"$( scutil --get ComputerName )\" "
                updateScriptLog "WELCOME DIALOG: • Current Local Host Name: \"$( scutil --get LocalHostName )\" "

            fi

            # User Name
            if [[ -n "${userName}" ]]; then
                # UNTESTED, UNSUPPORTED "YOYO" EXAMPLE
                reconOptions+="-endUsername \"${userName}\" "
            fi

            # Asset Tag
            if [[ -n "${assetTag}" ]]; then
                reconOptions+="-assetTag \"${assetTag}\" "
            fi

            # Real Name
            if [[ -n "${realName}" ]]; then
                # UNTESTED, UNSUPPORTED "YOYO" EXAMPLE
                reconOptions+="-realname \"${realName}\" "
            fi
            
            # E-mail
            if [[ -n "${email}" ]]; then
                # UNTESTED, UNSUPPORTED "YOYO" EXAMPLE
                reconOptions+="-email \"${email}\" "
            fi
            
            # Department
            if [[ -n "${department}" ]]; then
                # UNTESTED, UNSUPPORTED "YOYO" EXAMPLE
                reconOptions+="-department \"${department}\" "
            fi

            # Building
            if [[ -n "${building}" ]]; then reconOptions+="-building \"${building}\" "; fi
            
            # Room
            if [[ -n "${room}" ]]; then reconOptions+="-room \"${room}\" "; fi

            # Position
            if [[ -n "${position}" ]]; then reconOptions+="-position \"${position}\" "; fi

            # Output `recon` options to log
            updateScriptLog "WELCOME DIALOG: reconOptions: ${reconOptions}"

            ###
            # Display "Setup Your Mac" dialog (and capture Process ID)
            ###

            eval "${dialogSetupYourMacCMD[*]}" & sleep 0.3
            until pgrep -q -x "Dialog"; do
                outputLineNumberInVerboseDebugMode
                updateScriptLog "WELCOME DIALOG: Waiting to display 'Setup Your Mac' dialog; pausing"
                sleep 0.5
            done
            updateScriptLog "WELCOME DIALOG: 'Setup Your Mac' dialog displayed; ensure it's the front-most app"
            runAsUser osascript -e 'tell application "Dialog" to activate'
            if [[ -n "${overlayoverride}" ]]; then
                dialogUpdateSetupYourMac "overlayicon: ${overlayoverride}"
            fi
            ;;

        2)  # Process exit code 2 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} clicked Quit at Welcome dialog"
            completionActionOption="Quit"
            quitScript "1"
            ;;

        3)  # Process exit code 3 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} clicked infobutton"
            osascript -e "set Volume 3"
            afplay /System/Library/Sounds/Glass.aiff
            ;;

        4)  # Process exit code 4 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} allowed timer to expire"
            quitScript "1"
            ;;

        *)  # Catch all processing
            updateScriptLog "WELCOME DIALOG: Something else happened; Exit code: ${welcomeReturnCode}"
            quitScript "1"
            ;;

    esac

else

    ###
    # Select "Catch-all" policyJSON 
    ###

    outputLineNumberInVerboseDebugMode
    if [[ -n "$presetConfiguration" ]]; then
        symConfiguration="${presetConfiguration}"
    else
        symConfiguration="Catch-all ('Welcome' dialog disabled)"
    fi
    updateScriptLog "WELCOME DIALOG: Using ${symConfiguration} Configuration …"
    policyJSONConfiguration



    ###
    # Display "Setup Your Mac" dialog (and capture Process ID)
    ###

    eval "${dialogSetupYourMacCMD[*]}" & sleep 0.3
    until pgrep -q -x "Dialog"; do
        outputLineNumberInVerboseDebugMode
        updateScriptLog "WELCOME DIALOG: Waiting to display 'Setup Your Mac' dialog; pausing"
        sleep 0.5
    done
    updateScriptLog "WELCOME DIALOG: 'Setup Your Mac' dialog displayed; ensure it's the front-most app"
    runAsUser osascript -e 'tell application "Dialog" to activate'
    if [[ -n "${overlayoverride}" ]]; then
        dialogUpdateSetupYourMac "overlayicon: ${overlayoverride}"
    fi

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Iterate through policyJSON to construct the list for swiftDialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

outputLineNumberInVerboseDebugMode

dialog_step_length=$(get_json_value "${policyJSON}" "steps.length")
for (( i=0; i<dialog_step_length; i++ )); do
    listitem=$(get_json_value "${policyJSON}" "steps[$i].listitem")
    list_item_array+=("$listitem")
    icon=$(get_json_value "${policyJSON}" "steps[$i].icon")
    icon_url_array+=("$icon")
done



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Determine the "progress: increment" value based on the number of steps in policyJSON
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

outputLineNumberInVerboseDebugMode

totalProgressSteps=$(get_json_value "${policyJSON}" "steps.length")
progressIncrementValue=$(( 100 / totalProgressSteps ))
updateScriptLog "SETUP YOUR MAC DIALOG: Total Number of Steps: ${totalProgressSteps}"
updateScriptLog "SETUP YOUR MAC DIALOG: Progress Increment Value: ${progressIncrementValue}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# The ${array_name[*]/%/,} expansion will combine all items within the array adding a "," character at the end
# To add a character to the start, use "/#/" instead of the "/%/"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

outputLineNumberInVerboseDebugMode

list_item_string=${list_item_array[*]/%/,}
dialogUpdateSetupYourMac "list: ${list_item_string%?}"
for (( i=0; i<dialog_step_length; i++ )); do
    dialogUpdateSetupYourMac "listitem: index: $i, icon: ${icon_url_array[$i]}, status: pending, statustext: Pending …"
done
dialogUpdateSetupYourMac "list: show"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set initial progress bar
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

outputLineNumberInVerboseDebugMode

updateScriptLog "SETUP YOUR MAC DIALOG: Initial progress bar"
dialogUpdateSetupYourMac "progress: 1"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Close Welcome dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

outputLineNumberInVerboseDebugMode

dialogUpdateWelcome "quit:"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update Setup Your Mac's infobox
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

outputLineNumberInVerboseDebugMode

if [[ "${symConfiguration}" == *"Catch-all"* ]] || [[ -z "${symConfiguration}" ]] || [[ "${welcomeDialog}" != "userInput" ]]; then

    if [[ "${configurationDownloadEstimation}" == "true" ]]; then

        outputLineNumberInVerboseDebugMode

        checkNetworkQualityCatchAllConfiguration &

        updateScriptLog "SETUP YOUR MAC DIALOG: **Connection:**  \n- Download:  \n$mbps Mbps  \n\n**Estimate:**  \n- $(printf '%dh:%dm:%ds\n' $((configurationCatchAllEstimatedSeconds/3600)) $((configurationCatchAllEstimatedSeconds%3600/60)) $((configurationCatchAllEstimatedSeconds%60)))"

        infoboxConfiguration="**Connection:**  \n- Download:  \n$mbps Mbps  \n\n**Estimate:**  \n- $(printf '%dh:%dm:%ds\n' $((configurationCatchAllEstimatedSeconds/3600)) $((configurationCatchAllEstimatedSeconds%3600/60)) $((configurationCatchAllEstimatedSeconds%60)))"

    else

        # When `welcomeDialog` is set to `false` or `video`, set the value of `infoboxConfiguration` to null (thanks for the idea, @Manikandan!)
        infoboxConfiguration=""

    fi

else

    infoboxConfiguration="${symConfiguration}"

fi

infobox=""

if [[ -n ${comment} ]]; then infobox+="**Comment:**  \n$comment  \n\n" ; fi
if [[ -n ${computerName} ]]; then infobox+="**Computer Name:**  \n$computerName  \n\n" ; fi
if [[ -n ${userName} ]]; then infobox+="**Username:**  \n$userName  \n\n" ; fi
if [[ -n ${assetTag} ]]; then infobox+="**Asset Tag:**  \n$assetTag  \n\n" ; fi
if [[ -n ${infoboxConfiguration} ]]; then infobox+="**Configuration:**  \n$infoboxConfiguration  \n\n" ; fi
if [[ -n ${department} ]]; then infobox+="**Department:**  \n$department  \n\n" ; fi
if [[ -n ${building} ]]; then infobox+="**Building:**  \n$building  \n\n" ; fi
if [[ -n ${room} ]]; then infobox+="**Room:**  \n$room  \n\n" ; fi
if [[ -n ${position} ]]; then infobox+="**Position:**  \n$position  \n\n" ; fi

if { [[ "${promptForConfiguration}" != "true" ]] && [[ "${configurationDownloadEstimation}" == "true" ]]; } || { [[ "${welcomeDialog}" == "false" ]] || [[ "${welcomeDialog}" == "messageOnly" ]]; } then
    updateScriptLog "SETUP YOUR MAC DIALOG: Purposely NOT updating 'infobox'"
else
    updateScriptLog "SETUP YOUR MAC DIALOG: Updating 'infobox'"
    dialogUpdateSetupYourMac "infobox: ${infobox}"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update Setup Your Mac's helpmessage
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

outputLineNumberInVerboseDebugMode

if [[ "${symConfiguration}" != *"Catch-all"* ]]; then

    if [[ -n ${infoboxConfiguration} ]]; then

        if [[ -n "${supportTeamName}" ]]; then

        updateScriptLog "Update 'helpmessage' with support-related information …"

            helpmessage="If you need assistance, please contact:  \n\n**${supportTeamName}**  \n"
            
            if [[ -n "${supportTeamPhone}" ]]; then
                helpmessage+="- **Telephone:** ${supportTeamPhone}  \n"
            fi

            if [[ -n "${supportTeamEmail}" ]]; then
                helpmessage+="- **Email:** ${supportTeamEmail}  \n"
            fi

            if [[ -n "${supportTeamWebsite}" ]]; then
                helpmessage+="- **Web**: ${supportTeamHyperlink}  \n"
            fi
        
            if [[ -n "${supportKB}" ]]; then
                helpmessage+="- **Knowledge Base Article:** ${supportTeamErrorKB}  \n"
            fi

        fi

        updateScriptLog "Update 'helpmessage' with Configuration: ${infoboxConfiguration} …"
        helpmessage+="\n**Configuration:**\n- $infoboxConfiguration\n"

        helpmessage+="\n**Computer Information:**  \n"
        helpmessage+="- **Operating System:** ${macOSproductVersion} (${macOSbuildVersion})  \n"
        helpmessage+="- **Serial Number:** ${serialNumber}  \n"
        helpmessage+="- **Dialog:** ${dialogVersion}  \n"
        helpmessage+="- **Started:** ${timestamp}"
        
    fi

fi

dialogUpdateSetupYourMac "helpmessage: ${helpmessage}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# This for loop will iterate over each distinct step in the policyJSON
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

for (( i=0; i<dialog_step_length; i++ )); do 

    outputLineNumberInVerboseDebugMode

    # Initialize SECONDS
    SECONDS="0"

    # Creating initial variables
    listitem=$(get_json_value "${policyJSON}" "steps[$i].listitem")
    icon=$(get_json_value "${policyJSON}" "steps[$i].icon")
    progresstext=$(get_json_value "${policyJSON}" "steps[$i].progresstext")
    trigger_list_length=$(get_json_value "${policyJSON}" "steps[$i].trigger_list.length")

    # If there's a value in the variable, update running swiftDialog
    if [[ -n "$listitem" ]]; then
        updateScriptLog "\n\n# # #\n# SETUP YOUR MAC DIALOG: policyJSON > listitem: ${listitem}\n# # #\n"
        dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Installing …, "
    fi
    if [[ -n "$icon" ]]; then dialogUpdateSetupYourMac "icon: ${icon}"; fi
    if [[ -n "$progresstext" ]]; then dialogUpdateSetupYourMac "progresstext: $progresstext"; fi
    if [[ -n "$trigger_list_length" ]]; then

        for (( j=0; j<trigger_list_length; j++ )); do

            # Setting variables within the trigger_list
            trigger=$(get_json_value "${policyJSON}" "steps[$i].trigger_list[$j].trigger")
            validation=$(get_json_value "${policyJSON}" "steps[$i].trigger_list[$j].validation")
            case ${validation} in
                "Local" | "Remote" )
                    updateScriptLog "SETUP YOUR MAC DIALOG: Skipping Policy Execution due to '${validation}' validation"
                    ;;
                * )
                    confirmPolicyExecution "${trigger}" "${validation}"
                    ;;
            esac

        done

    fi

    validatePolicyResult "${trigger}" "${validation}"

    # Increment the progress bar
    dialogUpdateSetupYourMac "progress: increment ${progressIncrementValue}"

    # Record duration
    updateScriptLog "SETUP YOUR MAC DIALOG: Elapsed Time for '${trigger}' '${validation}': $(printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60)))"

done



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Complete processing and enable the "Done" button
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

outputLineNumberInVerboseDebugMode

finalise
