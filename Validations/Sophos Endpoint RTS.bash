#!/bin/bash

#####################################################################################
#
# Sophos Endpoint Validation
# for
# Setup Your Mac via swiftDialog
#
####################################################################################
#
# HISTORY
#
#   Version 0.0.1, 14-Dec-2022, Dan K. Snelson (@dan-snelson)
#   - Original Version
#
####################################################################################
# A script to collect the state of Sophos Endpoint's "Real Time Scanning > Files". #
# If Sophos Endpoint is not installed, "Not Installed" will be returned.           #
# If "Real Time Scanning > Files" is disabled, "Disabled" will be returned.        #
####################################################################################

RESULT="Not Installed"

if [[ -d /Applications/Sophos/Sophos\ Endpoint.app ]]; then
    if [[ -f /Library/Preferences/com.sophos.sav.plist ]]; then
        sophosOnAccessRunning=$( /usr/bin/defaults read /Library/Preferences/com.sophos.sav.plist OnAccessRunning )
        case ${sophosOnAccessRunning} in
            "0" ) RESULT="Disabled" ;;
            "1" ) RESULT="Running" ;;
             *  ) RESULT="Unknown" ;;
        esac
    else
        RESULT="Not Found"
    fi
fi

/bin/echo "<result>${RESULT}</result>"