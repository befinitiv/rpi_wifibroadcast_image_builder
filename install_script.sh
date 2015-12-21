#!/bin/bash

set -e

sudo apt-get update
sudo apt-get -y install vim mercurial libpcap-dev iw usbmount
sudo apt-get -y remove --auto-remove --purge libx11-.*



#install wifibroadcast
cd /home/pi
hg clone https://bitbucket.org/befi/wifibroadcast
cd wifibroadcast
make

#install new firmware
sudo cp "patches/AR9271/firmware/htc_9271.fw" "/lib/firmware"

#patch hello_video
cd /home/pi
hg clone https://bitbucket.org/befi/hello_video
sudo cp hello_video/video.c /opt/vc/src/hello_pi/hello_video/video.c
cd /opt/vc/src/hello_pi/
sudo ./rebuild.sh


#install osd
cd /home/pi
hg clone https://bitbucket.org/befi/frsky_omx_osd
cd frsky_omx_osd
sudo make


#install startup scripts
cd /home/pi
hg clone https://bitbucket.org/befi/wifibroadcast_fpv_scripts
cd wifibroadcast_fpv_scripts
sudo cp systemd/*.service /etc/systemd/system

#enable wifibroadcast, osd and shutdown pin
sudo systemctl enable wbcrxd
sudo systemctl enable wbctxd
sudo systemctl enable osd
sudo systemctl enable shutdown

#enable camera
sudo bash -c 'echo -e "\ngpu_mem=128\nstart_x=1\n" >> /boot/config.txt'

#disable sync option for usbmount
sudo sed -i 's/sync,//g' /etc/usbmount/usbmount.conf

#change hostname
CURRENT_HOSTNAME=`sudo cat /etc/hostname | sudo tr -d " \t\n\r"`
NEW_HOSTNAME="wbc"
if [ $? -eq 0 ]; then
  sudo sh -c "echo '$NEW_HOSTNAME' > /etc/hostname"
  sudo sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
fi


#always enable HDMI at 720p
sudo bash -c 'echo -e "\nhdmi_force_hotplug=1\nhdmi_drive=2\nhdmi_group=1\nhdmi_mode=4\n" >> /boot/config.txt'


#remove script that starts raspi config on first boot
sudo rm -rf /etc/profile.d/raspi-config.sh
