#!/bin/bash

#################################################################################
#
# Prompt to Setup Your Mac
#
# Purpose: Prompts users to login to Self Service / run the Setup Your Mac policy
#
# Reference: https://snelson.us/2022/07/setup-your-mac-please/
#
#################################################################################
#
# HISTORY
#
# Version 0.0.1, 22-Jul-2022, Dan K. Snelson (@dan-snelson)
#   Original version
#
# Version 0.0.2, 22-Jul-2022, Dan K. Snelson (@dan-snelson)
#   Added script execution delay (Parameter 4)
#
# Version 0.0.3, 28-Jul-2022, Dan K. Snelson (@dan-snelson)
#   Exit if odd-ball user is logged-in
#   Added "--ignorednd" and "--blurscreen" to Dialog command
#
# Version 0.0.4, 21-Aug-2023, Dan K. Snelson (@dan-snelson)
#   Updates inline with "Setup Your Mac (1.12.0)"
#   Added `quitkey`; Addresses Issue No. 83
#
# Version 0.0.5, 09-Sep-2023, Dan K. Snelson (@dan-snelson)
#   - Updated `dialogURL`
#
# Version 1.12.10, 15-Sep-2023, Dan K. Snelson (@dan-snelson)
#   - Reverted `mktemp`-created files to pre-SYM `1.12.1` behaviour
#   - Matched SYM version number
#
#################################################################################



#################################################################################
#
# Environmental Checks
#
#################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit gracefully if odd-ball users are logged in
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ { print $3 }' )

if [[ -z "${loggedInUser}" ]] \
|| [[ ${loggedInUser} == "loginwindow" ]] \
|| [[ ${loggedInUser} == "_mbsetupuser" ]] ; then
  echo "Odd-ball user \"${loggedInUser}\" logged in; exiting."
  exit 0
fi



#################################################################################
#
# Variables
#
#################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Global variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="1.12.10"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
secondsToWait="${4:-"2700"}"                                    # Parameter 4: "secondsToWait" setting; defaults to "2700"
scriptLog="/var/log/org.churchofjesuschrist.log"                # Your organization's default location for client-side logs
plistPath="/Library/Preferences/com.company.plist"              # Your organization's Reverse Domain Name Notation
jamfProPolicyName="@Setup Your Mac"
plistKey="Setup Your Mac"
selfServiceAppPath=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path )
dialogBinary="/usr/local/bin/dialog"
dialogCommandFile=$( mktemp -u /var/tmp/Prompt-to-Setup-Your-Mac.XXX )
swiftDialogMinimumRequiredVersion="2.3.2.4726"                  # This will be set and updated as dependancies on newer features change.



#################################################################################
#
# Pre-flight Checks
#
#################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
fi



#################################################################################
#
# Functions
#
#################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Client-side Script Logging Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt user to execute the Self Service policy via swiftDialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptUser() {

    updateScriptLog "Prompting user to execute the \"${jamfProPolicyName}\" policy; "

    dialogCheck

    title="Welcome to your new Mac!"
    message="Please complete the following steps to apply Church settings to your new Mac:  \n1. Login to the **Workforce App Store**  \n2. Locate the **Setup Your Mac** policy  \n3. Click **Setup**  \n\nIf you need assistance, please contact the GSD:  \n+1 (801) 555-1212 and mention **KB12345678**."

    appleInterfaceStyle=$( /usr/bin/defaults read /Users/"${loggedInUser}"/Library/Preferences/.GlobalPreferences.plist AppleInterfaceStyle 2>&1 )

    if [[ "${appleInterfaceStyle}" == "Dark" ]]; then
        icon="https://raw.githubusercontent.com/dan-snelson/Setup-Your-Mac/development/images/SYM_icon.png"
    else
        icon="https://raw.githubusercontent.com/dan-snelson/Setup-Your-Mac/development/images/SYM_icon.png"
    fi

    overlayicon=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path )

    dialogCMD="$dialogBinary --ontop --title \"$title\" \
    --message \"$message\" \
    --icon \"$icon\" \
    --button1text \"OK\" \
    --overlayicon \"$overlayicon\" \
    --titlefont 'size=28' \
    --messagefont 'size=14' \
    --infobuttontext 'KB12345678' \
    --infobuttonaction 'https://servicenow.company.com/support?id=kb_article_view&sysparm_article=KB12345678' \
    --small \
    --moveable \
    --timer 120 \
    --position 'centre' \
    --ignorednd \
    --blurscreen \
    --quitkey 'k' \
    --commandfile \"$dialogCommandFile\" "

    eval "$dialogCMD"

    returnCode=$?

    case ${returnCode} in

        0)  updateScriptLog "${loggedInUser} clicked OK; "
            ;;
        2)  updateScriptLog "${loggedInUser} clicked Button2; "
            ;;
        3)  updateScriptLog "${loggedInUser} clicked KB12345678; "
            ;;
        4)  updateScriptLog "${loggedInUser} allowed timer to expire; "
            ;;
        *)  updateScriptLog "Something else happened; swiftDialog Return Code: ${returnCode}; "
            ;;

    esac

    /bin/rm -f "$dialogCommandFile"

}



#--------------------- Edits below this line are optional ---------------------#



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

    fi

    # Remove the temporary working directory when done
    /bin/rm -Rf "$tempDirectory"

}



function dialogCheck() {

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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Gracefully exit for new enrollments
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function gracefullyExitForNewEnrollments() {

    testFile="/var/db/.AppleSetupDone"
    testFileSeconds=$( /bin/date -j -f "%s" "$(/usr/bin/stat -f "%m" $testFile)" +"%s" )
    nowSeconds=$( /bin/date +"%s" )
    ageInSeconds=$((nowSeconds-testFileSeconds))
    secondsToWaitHumanReadable=$( printf '"%dd, %dh, %dm, %ds"\n' $((secondsToWait/86400)) $((secondsToWait%86400/3600)) $((secondsToWait%3600/60)) $((secondsToWait%60)) )
    ageInSecondsHumanReadable=$( printf '"%dd, %dh, %dm, %ds"\n' $((ageInSeconds/86400)) $((ageInSeconds%86400/3600)) $((ageInSeconds%3600/60)) $((ageInSeconds%60)) )

    if [[ ${ageInSeconds} -le ${secondsToWait} ]]; then
        updateScriptLog "Set to wait ${secondsToWaitHumanReadable} and enrollment was ${ageInSecondsHumanReadable} ago; exiting."
        echo "${scriptResult}"
        exit 0
    else
        updateScriptLog "Set to wait ${secondsToWaitHumanReadable} and enrollment was ${ageInSecondsHumanReadable} ago, proceeding; "
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate Self Service installation
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function selfServiceValidation() {

    if [[ -d "${selfServiceAppPath}" ]]; then
        selfServiceInstalled="Yes"
    else
        selfServiceInstalled="No"
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate Logged-in User's Self Service Log
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function selfServiceLogValidation() {

    if [[ -f "/Users/${loggedInUser}/Library/Logs/JAMF/selfservice.log" ]]; then
        selfServiceLogInstalled="Yes"
    else
        selfServiceLogInstalled="No"
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate the number of times Self Service has been launched
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function selfServiceLaunchValidation() {

    if [[ ${selfServiceLogInstalled} == "Yes" ]]; then
        selfServiceLaunches=$( /usr/bin/grep "Application successfully launched" /Users/"${loggedInUser}"/Library/Logs/JAMF/selfservice.log | /usr/bin/wc -l | /usr/bin/tr -d ' ' )
    else
        updateScriptLog "Something went sideways when checking the number of times \"${selfServiceAppPath}\" has been launched; exiting."
        echo "${scriptResult}"
        exit 1
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate the number of times the user has logged into Self Service
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function selfServiceLoginValidation() {

    if [[ ${selfServiceLogInstalled} == "Yes" ]]; then
        selfServiceLogins=$( /usr/bin/grep "user logged in" /Users/"${loggedInUser}"/Library/Logs/JAMF/selfservice.log | /usr/bin/wc -l | /usr/bin/tr -d ' ' )
    else
        updateScriptLog "Something went sideways when checking the number of times ${loggedInUser} has logged in to \"${selfServiceAppPath}\"; exiting."
        echo "${scriptResult}"
        exit 1
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate Jamf's log
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function jamfLogValidation() {

    if [[ -f "/private/var/log/jamf.log" ]]; then
        jamfLogInstalled="Yes"
    else
        jamfLogInstalled="No"
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate Self Service Policy execution
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function selfServicePolicyValidation() {

    if [[ ${jamfLogInstalled} == "Yes" ]]; then
        selfServicePolicyExecutions=$( /usr/bin/grep "${jamfProPolicyName}" /private/var/log/jamf.log | /usr/bin/wc -l | /usr/bin/tr -d ' ' )
    else
        updateScriptLog "Something went sideways when checking the number of times ${loggedInUser} has executed the \"${jamfProPolicyName}\" policy; exiting."
        echo "${scriptResult}"
        exit 1
    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate Self Service Policy completion
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function selfServicePolicyCompletionValidation() {

    plistValue=$( /usr/bin/defaults read "${plistPath}" "${plistKey}" 2>&1 )

    case "${plistValue}" in

        *"does not exist"   )   selfServicePolicyCompletion="No"    ;;
        *                   )   selfServicePolicyCompletion="Yes"   ;;

    esac

}



#################################################################################
#
# Program
#
#################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n###\n# Setup Your Mac, please (${scriptVersion})\n# https://snelson.us/sym\n###\n"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check 1. Gracefully exit for new enrollments
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

gracefullyExitForNewEnrollments



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check 2. Validate Self Service installation
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

selfServiceValidation

if [[ ${selfServiceInstalled} == "No" ]]; then

    updateScriptLog "\"${selfServiceAppPath}\" was NOT installed; attempting re-installation; "
    /usr/local/bin/jamf update -verbose

    updateScriptLog "Updating inventory; "
    /usr/local/bin/jamf recon

    updateScriptLog "Exiting with error."
    echo "${scriptResult}"
    exit 1

else

    updateScriptLog "\"${selfServiceAppPath}\" is installed, proceeding; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check 3. Validate Logged-in User's Self Service Log
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

selfServiceLogValidation

if [[ ${selfServiceLogInstalled} == "No" ]]; then

    updateScriptLog "${loggedInUser}'s selfservice.log NOT found, launching \"${selfServiceAppPath}\"; "
    /usr/bin/su "${loggedInUser}" -c "/usr/bin/open \"${selfServiceAppPath}\""

    promptUser

    echo "${scriptResult}"
    exit 1

else

    updateScriptLog "${loggedInUser}'s selfservice.log found, proceeding; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check 4. Validate the number of times Self Service has been launched
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

selfServiceLaunchValidation

updateScriptLog "\"${selfServiceAppPath}\" has been launched for ${loggedInUser} ${selfServiceLaunches} times; "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check 5. Validate the number of times the user has logged into Self Service
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

selfServiceLoginValidation

if [[ ${selfServiceLogins} -le "0" ]]; then

    updateScriptLog "${loggedInUser} has logged in to \"${selfServiceAppPath}\" ${selfServiceLogins} times; "
    /usr/bin/su "${loggedInUser}" -c "/usr/bin/open \"${selfServiceAppPath}\""

    promptUser

    echo "${scriptResult}"
    exit 0

else

    updateScriptLog "${loggedInUser} has logged in to \"${selfServiceAppPath}\" ${selfServiceLogins} times; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check 6. Validate Jamf's log
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

jamfLogValidation

if [[ ${jamfLogInstalled} == "No" ]]; then

    updateScriptLog "jamf.log NOT found, attempting to re-manage; "
    /usr/local/bin/jamf manage -verbose

    updateScriptLog "Updating inventory; "
    /usr/local/bin/jamf recon

    updateScriptLog "Exiting with error."
    echo "${scriptResult}"
    exit 1

else

    updateScriptLog "jamf.log found, proceeding; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check 7. Validate Self Service Policy execution
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

selfServicePolicyValidation

if [[ ${selfServicePolicyExecutions} -le "0" ]]; then

    updateScriptLog "${loggedInUser} has started the \"${jamfProPolicyName}\" policy ${selfServicePolicyExecutions} times; "
    /usr/bin/su "${loggedInUser}" -c "/usr/bin/open \"${selfServiceAppPath}\""

    promptUser

    echo "${scriptResult}"
    exit 0

else

     updateScriptLog "${loggedInUser} has started the \"${jamfProPolicyName}\" policy ${selfServicePolicyExecutions} times; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check 8. Validate Self Service Policy completion
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

selfServicePolicyCompletionValidation

if [[ ${selfServicePolicyCompletion} == "No" ]]; then

    updateScriptLog "The \"${jamfProPolicyName}\" policy has NOT completed; launching \"${selfServiceAppPath}\"; "
    /usr/bin/su "${loggedInUser}" -c "/usr/bin/open \"${selfServiceAppPath}\""

    promptUser

    echo "${scriptResult}"
    exit 0

else

    updateScriptLog "Success! The \"${jamfProPolicyName}\" policy has completed; "

    updateScriptLog "Updating inventory; "
    /usr/local/bin/jamf recon
    
    updateScriptLog "Goodbye!"

    echo "${scriptResult}"
    exit 0

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "Catch-all exit; thank you!"

echo "${scriptResult}"

exit 0