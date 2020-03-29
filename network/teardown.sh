#!/bin/bash
# Must be run with sudo
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

if [ "$1" == "" ] || [ $# -gt 1 ]; then
    echo "Enter the name of an active ethernet interface in quotes"
    exit 1
fi

dhclient -r RLO_br

ip link set $1 nomaster
#ip link set $1 promisc off
ip link set RLO_vul down
ip link set RLO_kal down
# Removing the bridge off the ethernet
ip link del RLO_vul master RLO_br
ip link del RLO_kal master RLO_br
ip tuntap del RLO_vul mode tap
ip tuntap del RLO_kal mode tap
ip link delete RLO_br 

dhclient $1

