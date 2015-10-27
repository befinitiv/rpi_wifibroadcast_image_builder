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
NEW_HOSTNAME="wifibroadcastrx"
if [ $? -eq 0 ]; then
  sudo sh -c "echo '$NEW_HOSTNAME' > /etc/hostname"
  sudo sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
fi
echo "Changing hostname from $CURRENT_HOSTNAME to $NEW_HOSTNAME"