#!/bin/bash

#####################################################################################
#
# Palo Alto Networks GlobalProtect Status
# for
# Setup Your Mac via swiftDialog
#
####################################################################################
#
# HISTORY
#
#   Version 0.0.1, 16-Dec-2022, Dan K. Snelson (@dan-snelson)
#   - Original Version
#
###########################################################################################
# A script to collect the status of Palo Alto GlobalProtect.                              #
# • If Palo Alto GlobalProtect is not installed, "Not Installed" will be returned.        #
# • If the local user is not logged-in, "${loggedInUser} not logged-in" will be returned. #
# • If no gateway is selected, "Best Available Gateway selected" will be returned.        #
###########################################################################################

loggedInUser=$( /bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
appResult="Not Installed"
userResult="\"${loggedInUser}\" not Logged-in"
globalProtectDisabled="Disabled"

if [[ -d /Applications/GlobalProtect.app ]]; then # GlobalProtect.app found in /Applications

    # Read GlobalProtect's version number 
    appResult=$( /usr/bin/defaults read /Applications/GlobalProtect.app/Contents/Info.plist CFBundleShortVersionString )
    appResult="GlobalProtect ${appResult} installed; "

    # Read `disable-globalprotect` value
    globalProtectStatus=$( /usr/libexec/PlistBuddy -c "print :Palo\ Alto\ Networks:GlobalProtect:PanGPS:disable-globalprotect" /Library/Preferences/com.paloaltonetworks.GlobalProtect.settings.plist )
    case "${globalProtectStatus}" in
        0 ) globalProtectDisabled="GlobalProtect Running; " ;;
        1 ) globalProtectDisabled="GlobalProtect Disabled; " ;;
        * ) globalProtectDisabled="GlobalProtect Unknown; " ;;
    esac

    # Read the logged-in user's `User`
    userResult=$( /usr/bin/defaults read /Users/"${loggedInUser}"/Library/Preferences/com.paloaltonetworks.GlobalProtect.client User 2>&1 )
    if [[ "${userResult}"  == *"Does Not Exist" || -z "${userResult}" ]]; then
        userResult="${loggedInUser} NOT logged-in to GlobalProtect; "
    # elif [[ ! -z "${userResult}" ]]; then
    elif [[ -n "${userResult}" ]]; then

        userResult="\"${loggedInUser}\" logged-in to GlobalProtect; "
    fi

    # Read `Portal`
    companyPortal=$( /usr/libexec/PlistBuddy -c "print :Palo\ Alto\ Networks:GlobalProtect:PanSetup:Portal" /Library/Preferences/com.paloaltonetworks.GlobalProtect.settings.plist 2>&1 )

    # Read `default-gateway-name`
    gatewayResult=$( /usr/libexec/PlistBuddy -c "print :${companyPortal}:default-gateway-name" /Users/"${loggedInUser}"/Library/Preferences/com.paloaltonetworks.GlobalProtect.client.plist 2>&1 )
    if [[ "${gatewayResult}" == *"Does Not Exist" ]]; then
        gatewayResult="No default gateway specified"
    # elif [[ ! -z "${gatewayResult}" ]]; then
    elif [[ -n "${gatewayResult}" ]]; then
        gatewayResult="\"${loggedInUser}\" selected \"${gatewayResult}\" as default gateway"
    fi

else # GlobalProtect.app NOT found in /Applications; clear other variables
    userResult=""
    globalProtectDisabled=""
    gatewayResult=""

fi

/bin/echo "<result>${globalProtectDisabled}</result>"