#!/usr/bin/env bash
###############################################################################
# This script gets the Office 365 IPs and routes them directly via your       #
# gateway, so that you can still access the Office 365 services when          #
# connected to a VPN that blocks access to those addresses.                   #
#                                                                             #
# Requirements:                                                               #
# 1. jq - https://stedolan.github.io/jq/                                      #
# 2. sudo - changing the routing table requires root privileges               #
###############################################################################

# see https://docs.microsoft.com/en-us/office365/enterprise/office-365-ip-web-service for more info about how to generate the
# ClientRequestId
CLIENT_REQUEST_ID="" 

function addRoutes() {
    GATEWAY=`netstat -n -r -f inet | grep default | grep -v 'link#' | tail -1 | awk '{ print $2 }'`
    echo $GATEWAY > gateway.input
    rm ips.input
    for ip in `curl -s https://endpoints.office.com/endpoints/worldwide\?ClientRequestId\=${CLIENT_REQUEST_ID} | /usr/local/bin/jq -r '.[].ips|arrays|.[]' | egrep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(\/[0-9]{1,3})?"`; do
        echo $ip >> ips.input
        route add $ip $GATEWAY
    done
}

function removeRoutes() {
    if [[ -f gateway.input && -f ips.input ]]; then
        GATEWAY=`cat gateway.input`
        IPS=`cat ips.input`
        for ip in $IPS; do
            route delete $ip $GATEWAY
        done
        rm gateway.input
        rm ips.input
    fi
}

MODE=$1
if [[ "${MODE}" == "addRoutes" ]]; then
    addRoutes
elif [[ "${MODE}" == "removeRoutes" ]]; then
    removeRoutes
else
    echo "I don't know what to do."
fi
