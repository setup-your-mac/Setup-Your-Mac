#!/usr/bin/env bash
########################################################################################################################################
# A script to collect the state of CrowdStrike Falcon (thanks, ZT!)                                                                    #
# - If CrowdStrike Falcon is not installed, "Not Installed" will be returned.                                                          #
# - If CrowdStrike Falcon is HAS connected within the number of days specified as `lastConnectedVariance`, "Running" will be returned. #
# - If CrowdStrike Falcon is has NOT connected within the number of days specified as `lastConnectedVariance`,                         #
#   the last connected date will be returned.                                                                                          #
########################################################################################################################################

export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/
scriptVersion="0.0.3"
RESULT="Not Installed"
lastConnectedVariance="7" # The number of days before reporting device has not connected to the CrowdStrike Cloud.

###
# Functions
###

check_last_connection() {
    # Check if the last connected date is older than lastConnectedVariance
    # Arguments
    # $1 = (str) date formatted string, captured from "last connected date" in `falconctl stats Communications`
    # $2 = (int) number (of days)
    if [[ $( /bin/date -j -f "%b %d %Y %H:%M:%S" "$( echo "${1}" | /usr/bin/sed 's/,//g; s/ at//g; s/ [AP]M//g' )" +"%s" ) -lt $( /bin/date -j -v-"${2}"d +"%s" ) ]]; then
        returnResult+=" Last Connected: ${1};"
    fi
}

report_result() {
    # Arguments
    # $1 = (str) Message that will be returned
    local message="${1}"
    echo "<result>${message}</result>"
    exit 0

}

###
# Program
###

if [[ -d "/Applications/Falcon.app" ]]; then
    falconBinary="/Applications/Falcon.app/Contents/Resources/falconctl"
    falconAgentStats=$( "$falconBinary" stats agent_info Communications 2>&1 )

    if [[ "${falconAgentStats}" == *"Error: Error"* ]]; then

        case ${falconAgentStats} in
            *"status.bin"*  ) RESULT="'status.bin' NOT found" ;;
            *               ) RESULT="${falconAgentStats}" ;;
        esac        

        echo "<result>${RESULT}</result>"
        exit 1

    else

        connectionState=$( awk '/State:/{print $2}' <<< "$falconAgentStats" )
        established=$( echo "${falconAgentStats}" | /usr/bin/awk -F "[^Last] Established At:" '{print $2}' | /usr/bin/xargs )
        lastEstablished=$( echo "${falconAgentStats}" | /usr/bin/awk -F "Last Established At:" '{print $2}' | /usr/bin/xargs )

        if [[ "${connectionState}" == "connected" ]]; then

            # Compare if both were available.
            if [[ -n "${established}" && -n "${lastEstablished}" ]]; then

                # Check which is more recent.
                if [[ $( /bin/date -j -f "%b %d %Y %H:%M:%S" "$(echo "${established}" | /usr/bin/sed 's/,//g; s/ at//g; s/ [AP]M//g')" +"%s" ) -ge $( /bin/date -j -f "%b %d %Y %H:%M:%S" "$(echo "${lastEstablished}" | /usr/bin/sed 's/,//g; s/ at//g; s/ [AP]M//g')" +"%s" ) ]]; then
                    testConnectionDate="${established}"
                else
                    testConnectionDate="${lastEstablished}"
                fi

                # Check if the more recent date is older than seven days
                check_last_connection "${testConnectionDate}" $lastConnectedVariance

            elif [[ -n "${established}" ]]; then

                # If only the Established date was available, check if it is older than seven days.
                check_last_connection "${established}" $lastConnectedVariance

            elif [[ -n "${lastEstablished}" ]]; then

                # If only the Last Established date was available, check if it is older than seven days.
                check_last_connection "${lastEstablished}" $lastConnectedVariance

            else

                # If no connection date was available, return disconnected
                returnResult+=" Unknown Connection State;"

            fi

        elif [[ -n "${connectionState}" ]]; then

            # If no connection date was available, return state
            returnResult+=" Connection State: ${connectionState};"

        fi

    fi

else

    echo "<result>${RESULT}</result>"
    exit 0

fi

# Return the EA Value.
if [[ -n "${returnResult}" ]]; then

    # Trim leading space
    returnResult="${returnResult## }"
    # Trim trailing ;
    report_result "${returnResult%%;}"

else

    report_result "Running"

fi
