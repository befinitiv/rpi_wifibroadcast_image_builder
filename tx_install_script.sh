#!/bin/bash

set -e

sudo apt-get update
sudo apt-get -y install mercurial libpcap-dev iw usbmount
#remove desktop stuff
sudo apt-get -y remove --auto-remove --purge libx11-.*

#install wifibroadcast
cd /home/pi
hg clone https://bitbucket.org/befi/wifibroadcast
cd wifibroadcast
make

#install new firmware
sudo cp "patches/AR9271/firmware/htc_9271.fw" "/lib/firmware"


#install startup scripts
cd /home/pi
hg clone https://bitbucket.org/befi/wifibroadcast_fpv_scripts
cd wifibroadcast_fpv_scripts

sudo cp systemd/*.service /etc/systemd/system

#enable wifibroadcast 
sudo systemctl enable wbctxd

#enable camera
sudo bash -c 'echo -e "\ngpu_mem=128\nstart_x=1\n" >> /boot/config.txt'

#change hostname
CURRENT_HOSTNAME=`sudo cat /etc/hostname | sudo tr -d " \t\n\r"`
NEW_HOSTNAME="wifibroadcasttx"
if [ $? -eq 0 ]; then
  sudo sh -c "echo '$NEW_HOSTNAME' > /etc/hostname"
  sudo sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
fi

#remove script that starts raspi config on first boot
sudo rm -rf /etc/profile.d/raspi-config.sh
