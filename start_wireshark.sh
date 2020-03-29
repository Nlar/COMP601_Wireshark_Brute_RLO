#!/bin/bash
iplocation=$(which ip)
linkinfo=$($iplocation link show)
devicename=""
wiresharkrule="not ("
# Get all Mac Address that are not of interest
while read -r line
do
    if [ -z "$devicename" ]; then
        devicename=$(echo $line | sed -n -e 's/: <.*//p' | sed -n -e 's/[0-9][0-9]*[0-9]*: //p')
        if [ "$devicename" == "lo" ]; then
            devicename="skip"
        elif [ "$devicename" == "RLO_br" ]; then
            devicename="skip"
        elif [ "$devicename" == "RLO_kal" ]; then
            devicename="skip"
        elif [ "$devicename" == "RLO_vul" ]; then
            devicename="skip"
        fi
    else
        macaddress=$(echo $line | sed -n -e 's/.*ether //p' | sed -n -e 's/ brd.*//p')
        if [ "$devicename" != "skip" ]; then
            wiresharkrule="$wiresharkrule ether host $macaddress ||"
#            wiresharkrule="$wiresharkrule ether dst $macaddress ||"
        fi
        devicename=""
    fi
done <<< $($iplocation link show)
# Get the IP of the host that we are not interested in
while read -r line
do
    wiresharkrule="$wiresharkrule host $line ||"
done <<< $(ip addr show | grep "inet " | \
    grep -v "127\.[0-9][0-9]*[0-9]*\.[0-9][0-9]*[0-9]*\.[0-9][0-9]*[0-9]*" | \
    sed -n -e 's/[^0-9]*//p' | sed -n 's/[/].*//p')
wiresharkrule=$(echo $wiresharkrule | sed -n -e 's/||$//p')
wiresharkex="wireshark -i RLO_br -n -k -f  '$wiresharkrule )' "
eval $wiresharkex
