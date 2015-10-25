#!/bin/bash

set -e

sudo apt-get update
sudo apt-get -y install mercurial libpcap-dev iw usbmount

#install wifibroadcast
cd /home/pi
hg clone https://bitbucket.org/befi/wifibroadcast
cd wifibroadcast
make

#patch hello_video
cd /home/pi
hg clone https://bitbucket.org/befi/hello_video
sudo cp hello_video/video.c /opt/vc/src/hello_pi/hello_video/video.c
cd /opt/vc/src/hello_pi/
sudo ./rebuild.sh



#install startup scripts
cd /home/pi
hg clone https://bitbucket.org/befi/wifibroadcast_fpv_scripts
cd wifibroadcast_fpv_scripts
sudo cp init.d/wbcrxd /etc/init.d
sudo update-rc.d wbcrxd start

#enable shutdown switch
sudo cp init.d/shutdown /etc/init.d
sudo update-rc.d shutdown start


#disable sync option for usbmount
sudo sed -i 's/sync,//g' /etc/usbmount/usbmount.conf

