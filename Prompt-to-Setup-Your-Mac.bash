#!/bin/bash

#################################################################################
#
# MARK: Prompt to Setup Your Mac
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
# Additions, 22-May-2023, Søren Theilgaard (@theilgaard, GitHub: @Theile)
#
#################################################################################



#################################################################################
#
# MARK: Environmental Checks
#
#################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# NOTE: Exit gracefully if odd-ball users are logged in
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

loggedInUser=$( stat -f "%Su" /dev/console ) # @theilgaard

if [[ -z "${loggedInUser}" ]] \
|| [[ ${loggedInUser} == "loginwindow" ]] \
|| [[ ${loggedInUser} == "_mbsetupuser" ]] ; then
  echo "Odd-ball user \"${loggedInUser}\" logged in; exiting."
  exit 0
fi



#################################################################################
#
# MARK: Variables
#
#################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# NOTE: Global variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="0.0.3"
scriptResult="Prompt to Setup Your Mac (${scriptVersion}); "
jamfProPolicyName="@Setup Your Mac"
plistPath="/Library/Preferences/com.company.plist"
plistKey="Setup Your Mac"
selfServiceAppPath=$( /usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path )
dialogApp="/usr/local/bin/dialog"
dialogCommandFile=$( /usr/bin/mktemp "/var/tmp/Prompt-to-Setup-Your-Mac.XXXXXXX" )



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# NOTE: Check for a specified "secondsToWait" setting (Parameter 4); defaults to "2700"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${4}" != "" ]] && [[ "${secondsToWait}" == "" ]]; then
  secondsToWait="${4}"
  scriptResult+="Using ${secondsToWait} as the number of seconds before script execution; "
else
  secondsToWait="2700"
  scriptResult+="Parameter 4 is blank; using ${secondsToWait} as the number of seconds before script execution; "
fi



#################################################################################
#
# MARK: Functions
#
#################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prompt user to execute the Self Service policy via swiftDialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function promptUser() {

    scriptResult+="Prompting user to execute the \"${jamfProPolicyName}\" policy; "

    dialogCheck

    title="Welcome to your new Mac!"
    message="Please complete the following steps to apply Church settings to your new Mac:  \n1. Login to the **Workforce App Store**  \n2. Locate the **Setup Your Mac** policy  \n3. Click **Setup**  \n\nIf you need assistance, please contact the GSD:  \n+1 (801) 555-1212 and mention **KB12345678**."

    appleInterfaceStyle=$( /usr/bin/defaults read /Users/"${loggedInUser}"/Library/Preferences/.GlobalPreferences.plist AppleInterfaceStyle 2>&1 )

    if [[ "${appleInterfaceStyle}" == "Dark" ]]; then
        icon="/System/Library/CoreServices/Finder.app"
    else
        icon="/System/Library/CoreServices/Finder.app"
    fi

    overlayicon=$( defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path )

    dialogCMD="$dialogApp --ontop --title \"$title\" \
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
    --commandfile \"$dialogCommandFile\" "

    eval "$dialogCMD"

    returnCode=$?

    case ${returnCode} in

        0)  scriptResult+="${loggedInUser} clicked OK; "
            ;;
        2)  scriptResult+="${loggedInUser} clicked Button2; "
            ;;
        3)  scriptResult+="${loggedInUser} clicked KB12345678; "
            ;;
        4)  scriptResult+="${loggedInUser} allowed timer to expire; "
            ;;
        *)  scriptResult+="Something else happened; swiftDialog Return Code: ${returnCode}; "
            ;;

    esac

    /bin/rm -f "$dialogCommandFile"

}



# MARK: -------------- Edits below this line are optional ---------------------#



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for / install swiftDialog (thanks, Adam!)
# https://github.com/acodega/dialog-scripts/blob/main/dialogCheckFunction.sh
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogCheck(){
  # Get the URL of the latest PKG From the Dialog GitHub repo
  dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
  # Expected Team ID of the downloaded PKG
  expectedDialogTeamID="PWA5E9TQ59"

  # Check for Dialog and install if not found
  if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
    echo "Dialog not found. Installing..."
    # Create temporary working directory
    workDirectory=$( /usr/bin/basename "$0" )
    tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
    # Download the installer package
    /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"
    # Verify the download
    teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
    # Install the package if Team ID validates
    if [ "$expectedDialogTeamID" = "$teamID" ] || [ "$expectedDialogTeamID" = "" ]; then
      /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
    else
      jamfDisplayMessage "Dialog Team ID verification failed."
      exit 1
    fi
    # Remove the temporary working directory when done
    /bin/rm -Rf "$tempDirectory"  
  else
    scriptResult+="Dialog v$(dialog --version) installed, proceeding; "
  fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Message via the jamf binary
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function jamfDisplayMessage() {
    scriptResult+="${1}; "
	/usr/local/jamf/bin/jamf displayMessage -message "${1}" &
}



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
        scriptResult+="Set to wait ${secondsToWaitHumanReadable} and enrollment was ${ageInSecondsHumanReadable} ago; exiting."
        echo "${scriptResult}"
        exit 0
    else
        scriptResult+="Set to wait ${secondsToWaitHumanReadable} and enrollment was ${ageInSecondsHumanReadable} ago, proceeding; "
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
        scriptResult+="Something went sideways when checking the number of times \"${selfServiceAppPath}\" has been launched; exiting."
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
        scriptResult+="Something went sideways when checking the number of times ${loggedInUser} has logged in to \"${selfServiceAppPath}\"; exiting."
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
        scriptResult+="Something went sideways when checking the number of times ${loggedInUser} has executed the \"${jamfProPolicyName}\" policy; exiting."
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
# MARK: Program
#
#################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# NOTE: Check 1. Gracefully exit for new enrollments
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

gracefullyExitForNewEnrollments



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# NOTE: Check 2. Validate Self Service installation
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

selfServiceValidation

if [[ ${selfServiceInstalled} == "No" ]]; then

    scriptResult+="\"${selfServiceAppPath}\" was NOT installed; attempting re-installation; "
    /usr/local/bin/jamf update -verbose

    scriptResult+="Updating inventory; "
    /usr/local/bin/jamf recon

    scriptResult+="Exiting with error."
    echo "${scriptResult}"
    exit 1

else

    scriptResult+="\"${selfServiceAppPath}\" is installed, proceeding; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# NOTE: Check 3. Validate Logged-in User's Self Service Log
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

selfServiceLogValidation

if [[ ${selfServiceLogInstalled} == "No" ]]; then

    scriptResult+="${loggedInUser}'s selfservice.log NOT found, launching \"${selfServiceAppPath}\"; "
    /usr/bin/su "${loggedInUser}" -c "/usr/bin/open \"${selfServiceAppPath}\""

    promptUser

    echo "${scriptResult}"
    exit 1

else

    scriptResult+="${loggedInUser}'s selfservice.log found, proceeding; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# NOTE: Check 4. Validate the number of times Self Service has been launched
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

selfServiceLaunchValidation

scriptResult+="\"${selfServiceAppPath}\" has been launched for ${loggedInUser} ${selfServiceLaunches} times; "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# NOTE: Check 5. Validate the number of times the user has logged into Self Service
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

selfServiceLoginValidation

if [[ ${selfServiceLogins} -le "0" ]]; then

    scriptResult+="${loggedInUser} has logged in to \"${selfServiceAppPath}\" ${selfServiceLogins} times; "
    /usr/bin/su "${loggedInUser}" -c "/usr/bin/open \"${selfServiceAppPath}\""

    promptUser

    echo "${scriptResult}"
    exit 0

else

    scriptResult+="${loggedInUser} has logged in to \"${selfServiceAppPath}\" ${selfServiceLogins} times; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# NOTE: Check 6. Validate Jamf's log
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

jamfLogValidation

if [[ ${jamfLogInstalled} == "No" ]]; then

    scriptResult+="jamf.log NOT found, attempting to re-manage; "
    /usr/local/bin/jamf manage -verbose

    scriptResult+="Updating inventory; "
    /usr/local/bin/jamf recon

    scriptResult+="Exiting with error."
    echo "${scriptResult}"
    exit 1

else

    scriptResult+="jamf.log found, proceeding; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# NOTE: Check 7. Validate Self Service Policy execution
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

selfServicePolicyValidation

if [[ ${selfServicePolicyExecutions} -le "0" ]]; then

    scriptResult+="${loggedInUser} has started the \"${jamfProPolicyName}\" policy ${selfServicePolicyExecutions} times; "
    /usr/bin/su "${loggedInUser}" -c "/usr/bin/open \"${selfServiceAppPath}\""

    promptUser

    echo "${scriptResult}"
    exit 0

else

     scriptResult+="${loggedInUser} has started the \"${jamfProPolicyName}\" policy ${selfServicePolicyExecutions} times; "

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# NOTE: Check 8. Validate Self Service Policy completion
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

selfServicePolicyCompletionValidation

if [[ ${selfServicePolicyCompletion} == "No" ]]; then

    scriptResult+="The \"${jamfProPolicyName}\" policy has NOT completed; launching \"${selfServiceAppPath}\"; "
    /usr/bin/su "${loggedInUser}" -c "/usr/bin/open \"${selfServiceAppPath}\""

    promptUser

    echo "${scriptResult}"
    exit 0

else

    scriptResult+="Success! The \"${jamfProPolicyName}\" policy has completed; "

    scriptResult+="Updating inventory; "
    /usr/local/bin/jamf recon
    
    scriptResult+="Goodbye!"

    echo "${scriptResult}"
    exit 0

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# MARK: Exit
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptResult+="Catch-all exit; thank you!"

echo "${scriptResult}"

exit 0