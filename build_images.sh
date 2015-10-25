#!/bin/bash

# apt dependencies: qemu qemu-user-static binfmt-support

set -e
set -o xtrace


BASE_IMAGE_URL="http://downloads.raspberrypi.org/raspbian/images/raspbian-2015-05-07"
BASE_IMAGE="2015-05-05-raspbian-wheezy"



function patch_rpi_image {
	#make a copy of the image to RX
	IMAGE_FILE="$1"
	INSTALL_SCRIPT="$2"
	cp data/$BASE_IMAGE".img" $IMAGE_FILE

	#mount the image
	mkdir -p data/mnt
	sudo mount "$IMAGE_FILE" -o loop,offset=$((122880*512)),rw data/mnt

	#clear the preload file
	sudo cp data/mnt/etc/ld.so.preload data/mnt/root
	sudo cp /dev/null data/mnt/etc/ld.so.preload

	cp $INSTALL_SCRIPT data/mnt/home/pi
	sudo chroot --userspec=1000:1000 data/mnt /bin/bash "/home/pi/$INSTALL_SCRIPT"

	sudo cp data/mnt/root/ld.so.preload data/mnt/etc/ld.so.preload
	sudo umount data/mnt
}






#first, download raspian image
mkdir -p data
cd data

if [ ! -f $BASE_IMAGE".img" ]
then
	wget $BASE_IMAGE_URL/$BASE_IMAGE".zip"
	unzip $BASE_IMAGE".zip"
fi

cd ..

RX_IMAGE_FILE="data/RX_$BASE_IMAGE"".img"
RX_INSTALL_SCRIPT="rx_install_script.sh"
patch_rpi_image "$RX_IMAGE_FILE" "$RX_INSTALL_SCRIPT"

TX_IMAGE_FILE="data/TX_$BASE_IMAGE"".img"
TX_INSTALL_SCRIPT="tx_install_script.sh"
patch_rpi_image "$TX_IMAGE_FILE" "$TX_INSTALL_SCRIPT"

