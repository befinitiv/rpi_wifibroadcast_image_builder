#!/bin/bash

set -e

sudo apt-get update
sudo apt-get -y install mercurial libpcap-dev iw usbmount

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
sudo cp init.d/wbctxd /etc/init.d
sudo update-rc.d wbctxd start

#enable camera
sudo bash -c "echo \"gpu_mem=128\" >> /boot/config.txt"
sudo bash -c "echo \"start_x=1\" >> /boot/config.txt"

#disable desktop
[ -e /etc/init.d/lightdm ] && sudo update-rc.d lightdm disable 2
if [ -e /etc/profile.d/boottoscratch.sh ]; then
  sudo rm -f /etc/profile.d/boottoscratch.sh
  sudo sed -i /etc/inittab \
    -e "s/^#\(.*\)#\s*BTS_TO_ENABLE\s*/\1/" \
    -e "/#\s*BTS_TO_DISABLE/d"
  telinit q
fi

#change hostname
CURRENT_HOSTNAME=`sudo cat /etc/hostname | sudo tr -d " \t\n\r"`
NEW_HOSTNAME="wifibroadcasttx"
if [ $? -eq 0 ]; then
  sudo sh -c "echo '$NEW_HOSTNAME' > /etc/hostname"
  sudo sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
fi