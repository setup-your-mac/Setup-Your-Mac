#!/bin/zsh

#####################################################################################
#
# Printer Validation
# for
# Setup Your Mac via swiftDialog
#
####################################################################################
#
# HISTORY
#
#   Version 0.0.1, 25-Apr-2023, @drtaru
#   - Original Version
#
####################################################################################
# A script to find printers with lpstat and build an array
#
# To get possible values for the script run the following on a machine that only
# has the desired printers added via the same method as your jamf policies
#
# lpstat -p 2>/dev/null | awk '{print $2}' | sed '/^$/d'
#
####################################################################################


foundPrinters=($(lpstat -p 2>/dev/null | awk '{print $2}' | sed '/^$/d'))

# Place the resulting values from your lpstat command in the =~ "" blocks
# You can add as many || or commands as needed to match expected printers
#
# NOTE: If any printer is missing the entire validation will fail


if [[ ! " ${foundPrinters[*]} " =~ "Printer1" || ! " ${foundPrinters[*]} " =~ "Printer2" ]]; then
    echo "Failure"
else
    echo "Running"
fi