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
    
ip link add name RLO_br type bridge
ip link set RLO_br up
ip tuntap add dev RLO_vul mode tap
ip tuntap add dev RLO_kal mode tap
ip link set RLO_vul master RLO_br
ip link set RLO_kal master RLO_br
ip link set RLO_vul up
ip link set RLO_kal up

# Adding the active ethernet interface to allow for internet
#ip link set $1 promisc on
ip link set $1 master RLO_br up

dhclient -r $1
dhclient RLO_br

#iptables -t nat -A POSTROUTING -o $1 -j MASQUERADE
#iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
#iptables -A FORWARD -i RLO_br -o $1 -j ACCEPT
