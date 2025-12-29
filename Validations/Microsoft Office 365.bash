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
#   Version 0.0.3, 25-Apr-2023, Andrew Clark (@drtaru)
#   - Changed Success result to Success to map to new SYM validation status
#   Version 0.0.4, 13-Jun-2024, Lewis B (@master-vodawagner)
#   - Added ability to delay whilst Microsoft AutoUpdater is running/patching apps
#
####################################################################################
# A script to collect the installation status of Microsoft Office 365.             #
#                                                                                  #
# If an expected app is NOT installed, the `appChecks` variable will include the   #
# keyword "NOT", and the script will report a failure.                             #
#                                                                                  #
# If all expected apps are installed, the `RESULT` variable will include the       #
# keyword "Success"; see the following post:                                       #                     
# https://snelson.us/2023/01/setup-your-mac-validation/                            #
####################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

# Set Apps to check, valid options are: "Microsoft Excel" "Microsoft OneNote" "Microsoft Outlook" "Microsoft PowerPoint" "Microsoft Word" "OneDrive"
appsToCheck=("Microsoft Excel" "Microsoft OneNote" "Microsoft Outlook" "Microsoft PowerPoint" "Microsoft Word" "OneDrive")
appChecks=""
RESULT=""
IFS=""


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

# Allow Microsoft AutoUpdater to scan/patch apps before validating install
while pgrep -a "Microsoft AutoUpdate"; do
    echo "Microsoft AutoUpdater is still running; pausing for 10 seconds"
    sleep 10
done

for app in ${appsToCheck[@]}; do
  appCheck "$app"
done



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Output Results
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

case "${appChecks}" in
    *"NOT"* ) RESULT="Failure: ${appChecks}" ;;
    *       ) RESULT="Success: ${appChecks}" ;;
esac

/bin/echo "<result>${RESULT}</result>"
