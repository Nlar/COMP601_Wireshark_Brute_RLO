#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi
if [ "$1" == "" ] || [ $# -gt 1 ]; then
    echo "Enter the name of an active ethernet interface in quotes"
    exit 1
fi

./network/setup.sh $1
./server/vuln_web_server.sh &
vuln_pid=`echo ${!}`
sleep 15        # Give some time to offset the boots
./attacker/attacker_client.sh $vuln_pid &
kali_pid=`echo ${!}`

# Keep Network the the changed state until the environment clears
while kill -0 $vuln_pid 2> /dev/null; do
    sleep 10
done
while kill -0 $kali_pid 2> /dev/null; do
    sleep 10
done

./network/teardown.sh $1
