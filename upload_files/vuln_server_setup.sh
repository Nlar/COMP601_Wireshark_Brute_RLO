#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

# Make sure the system has been updated, but don't keep running the update
lastupdate=$(ls -l /var/lib/apt/periodic/update-success-stamp | sed -n -e "s/.*root 0 //p" | sed -ne "s/ [0-9][0-9]:.*//p")
today=$(date | sed -n -e 's/[A-Z][a-z][a-z] //p' | sed -ne 's/ [0-9][0-9]:.*//p')
if [ "lastupdate" == "$today" ]; then
    apt-get update
fi
if [ -z "$today" ]; then	# This occurs when sed hasn't been updated
    apt-get update
fi
# If there is no update this takes no time
apt-get upgrade
if [ ! -d /var/www/html/DVWA ]; then
    echo "Installing packages"
    apt-get -y install apache2 mysql-server php php7.2-mysql php-gd libapache2-mod-php
    echo "Downloading DVWA"
    git clone https://github.com/ethicalhack3r/DVWA
    mv ./DVWA /var/www/html
fi
if [ -f /var/www/html/DVWA/config/config.inc.php ]; then
    rm /var/www/html/DVWA/config/config.inc.php
fi

cp /var/www/html/DVWA/config/config.inc.php.dist /var/www/html/DVWA/config/config.inc.php
# Change PHP setting allow_url_fopen: Enabled
phpline=$(php --ini | grep php.ini$ | sed -n -e 's/[^/]*//p' | sed 's/cli/apache2/')
echo "Adjusting PHP Settings"
sed -i 's/allow_url_include = Off/allow_url_include = On/g' $phpline
#cat $phpline | grep -i persistent
# Add writable folder and file
chmod 777 /var/www/html/DVWA/hackable/uploads
chmod 666 /var/www/html/DVWA/external/phpids/0.6/lib/IDS/tmp/phpids_log.txt
chmod 777 /var/www/html/DVWA/config
systemctl restart apache2.service
password="$(openssl rand -base64 8)"
username=vuln_db
# Deleting the user incase this script is run several times
mysql -e "DROP USER '$username'@'localhost';"
mysql -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '$password';"
mysql -e "GRANT ALL PRIVILEGES ON * . * TO '$username'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

#echo $password
sed -i "s/'db_user' ][^;]*/'db_user' ]     = 'vuln_db'/g" /var/www/html/DVWA/config/config.inc.php
sed -i "s/'db_password' ][^;]*/'db_password' ]  = '$password'/g" /var/www/html/DVWA/config/config.inc.php

# Remove the floppy drive that causes errors
if grep -q "blacklist floppy"  /etc/modprobe.d/blacklist.conf; then
    echo "Floppy Blacklist Present"
else
   echo "" >> /etc/modprobe.d/blacklist.conf
   echo "blacklist floppy" >> /etc/modprobe.d/blacklist.conf
fi

# Disable cloud
#cloudfile='/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg'
#if [ ! -f $cloudfile ]; then
#    echo 'network: {config:disabled}' > $cloudfile
#fi

# Generate the database through the webform
ipaddress=$(ip addr show | grep "inet " | \
    grep -v "127\.[0-9][0-9]*[0-9]*\.[0-9][0-9]*[0-9]*\.[0-9][0-9]*[0-9]*" | \
    sed -n -e 's/[^0-9]*//p' | sed -n 's/[/].*//p')
echo "Create the database through this webpage: "
echo "http://$ipaddress/DVWA/setup.php"
read -n 1 -s -r -p "Press any key to continue"
echo ""

# QEMU may assign the same mac to both machines.  Change This One
macoverridefile='/lib/systemd/network/10-ether0.link'
defaultpolicy='/lib/systemd/network/99-default.link'
if [ -f $macoverridefile ]; then
    echo "Mac Address Seems Fine.  Delete /lib/systemd/network/10-ether0.link and re-run this script if both machines are unreachable"
else
    echo "Adjusting Mac Address"
    currentmac=$(ip link show | grep ether | sed -n 's/ brd.*//p' | sed -n 's/.*ether //p')
    macfront=$(echo $currentmac | awk '{print substr($0,0,8)}')
    hexcharacters="0123456789ABCDEF"
    newmac="$macfront$macend"
    macend=$(openssl rand -hex 3 | sed -e 's/\(..\)/:\1/g' )
    newmac="$macfront$macend"
    if [ $newmac == $currentmac ]; then
        macend=$(openssl rand -hex 3 | sed -e 's/\(..\)/:\1/g' )
        newmac="$macfront$macend"
    fi
    echo "[Match]" >> $macoverridefile
    echo "MACAddress=$currentmac" >> $macoverridefile
    echo "[Link]" >> $macoverridefile
    echo "MACAddress=$newmac" >> $macoverridefile
echo "** $defaultpolicy"
    sed -i 's/persistent/none/g' $defaultpolicy
    echo "The server will now reboot"
    read -n 1 -s -r -p "Press any key to continue"
    echo
    shutdown -r now
fi
