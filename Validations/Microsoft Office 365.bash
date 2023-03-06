#!/bin/bash

#####################################################################################
#
# Microsoft Office 365
# for
# Setup Your Mac via swiftDialog
#
####################################################################################
#
# HISTORY
#
#   Version 0.0.1, 06-Mar-2023, Dan K. Snelson (@dan-snelson)
#   - Original Version
#
####################################################################################
# A script to collect the installation status of Microsoft Office 365.             #
#                                                                                  #
# If an expected app is NOT installed, the `appChecks` variable will include the   #
# keyword "NOT", and the script will report a failure.                             #
#                                                                                  #
# If all expected apps are installed, the `RESULT` variable will include the       #
# keyword "Running"; see the following post:                                       #                     
# https://snelson.us/2023/01/setup-your-mac-validation/                            #
####################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

appChecks=""
RESULT=""



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for an app's Info.plist
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function appCheck() {
    app="${1}"
    if [[ -f "/Applications/${app}.app/Contents/Info.plist" ]]; then
        appChecks+="${app} installed; "
    else
        appChecks+="${app} NOT installed; "
    fi

}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check for Microsoft Office 365 apps (i.e., Microsoft_365_and_Office_16.70.23021201_Installer.pkg)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

appCheck "Microsoft Excel"
appCheck "Microsoft OneNote"
appCheck "Microsoft Outlook"
appCheck "Microsoft PowerPoint"
appCheck "Microsoft Word"
appCheck "OneDrive"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Output Results
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

case "${appChecks}" in
    *"NOT"* ) RESULT="Failure: ${appChecks}" ;;
    *       ) RESULT="Running: ${appChecks}" ;;
esac

/bin/echo "<result>${RESULT}</result>"