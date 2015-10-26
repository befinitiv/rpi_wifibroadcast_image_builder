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


