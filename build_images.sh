#!/bin/bash

# apt dependencies: qemu qemu-user-static binfmt-support

set -e
set -o xtrace


BASE_IMAGE_URL="http://downloads.raspberrypi.org/raspbian/images/raspbian-2015-09-28"
BASE_IMAGE="2015-09-24-raspbian-jessie"


DATA_DIR="$PWD/data"
MNT_DIR="$DATA_DIR/mnt"
KERNEL_DIR="$DATA_DIR/kernel"
KERNEL_PATCHES="$PWD/kernel_patches/*.patch"


function download_image {
	#first, download raspian image
	pushd $PWD
	cd data

	if [ ! -f $BASE_IMAGE".img" ]
	then
		if [ ! -f $BASE_IMAGE".zip" ]
		then
			wget $BASE_IMAGE_URL/$BASE_IMAGE".zip"
		fi
		unzip $BASE_IMAGE".zip"
	fi

	popd
}

function download_kernel_and_tools {
	pushd $PWD
	
	mkdir -p "$KERNEL_DIR"
	cd "$KERNEL_DIR"

	if [ ! -d tools ]
	then
		git clone https://github.com/raspberrypi/tools
	fi

	if [ ! -d linux ]
	then
		git clone --depth=1 https://github.com/raspberrypi/linux
	fi

	#revert any previous changes, so that any patches can be applied flawlessly
	cd linux
	git checkout .

	popd
}

function patch_kernel {
	pushd $PWD
	cd "$KERNEL_DIR/linux"

	for f in $KERNEL_PATCHES
	do
		echo "Applying patch $f"
		patch -N -p1 < $f
	done

	popd
}

function compile_kernel {	
	export PATH=$PATH:"$KERNEL_DIR/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin"

	pushd $PWD
	cd "$KERNEL_DIR/linux"

	#TODO add RPI2 support
	KERNEL=kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- make bcmrpi_defconfig
	KERNEL=kernel ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- make -j4 zImage modules dtbs

	popd
}

#args: fat-partition, ext4-partition
function install_kernel {
	pushd $PWD

	cd "$KERNEL_DIR/linux"

	#install modules
	sudo make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH="$2" modules_install
	
	#install kernel and fdt
	sudo scripts/mkknlimg arch/arm/boot/zImage "$1/kernel.img"
	sudo cp arch/arm/boot/dts/*.dtb "$1"
	sudo cp arch/arm/boot/dts/overlays/*.dtb* "$1/overlays"
	sudo cp arch/arm/boot/dts/overlays/README "$1/overlays"

	popd
}

function patch_rpi_image {
	#make a copy of the base image
	IMAGE_FILE="$1"
	INSTALL_SCRIPT="$2"
	cp $DATA_DIR/$BASE_IMAGE".img" $IMAGE_FILE

	#mount the image
	mkdir -p "$MNT_DIR"
	# rootfs
	mountpoint -q "$MNT_DIR" || sudo mount "$IMAGE_FILE" -o loop,offset=$((122880*512)),rw "$MNT_DIR"
	# boot
	mountpoint -q "$MNT_DIR/boot" || sudo mount "$IMAGE_FILE" -o loop,offset=$((8192*512)),rw "$MNT_DIR/boot"


	mountpoint -q "$MNT_DIR/dev/" || sudo mount --bind /dev "$MNT_DIR/dev/"
	mountpoint -q "$MNT_DIR/sys/" || sudo mount --bind /sys "$MNT_DIR/sys/"
	mountpoint -q "$MNT_DIR/proc/" || sudo mount --bind /proc "$MNT_DIR/proc/"
	mountpoint -q "$MNT_DIR/dev/pts/" || sudo mount --bind /dev/pts "$MNT_DIR/dev/pts"

	#install new kernel
	install_kernel "$MNT_DIR/boot" "$MNT_DIR"

	#install qemu
	sudo cp /usr/bin/qemu-arm-static "$MNT_DIR/usr/bin"

	#clear the preload file
	sudo cp "$MNT_DIR/etc/ld.so.preload" "$MNT_DIR/root"
	sudo cp /dev/null "$MNT_DIR/etc/ld.so.preload"

	#save the version of this build script inside the raspi image
	hg summary > "$MNT_DIR/home/pi/rpi_wifibroadcast_image_builder_version.txt"
	hg diff >> "$MNT_DIR/home/pi/rpi_wifibroadcast_image_builder_version.txt"

	cp $INSTALL_SCRIPT "$MNT_DIR/home/pi"
	sudo mount --bind /etc/resolv.conf "$MNT_DIR/etc/resolv.conf"
	sudo chroot --userspec=1000:1000 "$MNT_DIR" /bin/bash "/home/pi/$INSTALL_SCRIPT"

	sudo cp "$MNT_DIR/root/ld.so.preload" "$MNT_DIR/etc/ld.so.preload"

	sudo umount -l "$MNT_DIR/sys"
	sudo umount -l "$MNT_DIR/proc"
	sudo umount -l "$MNT_DIR/dev/pts"
	sudo umount -l "$MNT_DIR/dev"

	sudo umount -l "$MNT_DIR/boot"
	sudo umount -l "$MNT_DIR/etc/resolv.conf"
	sudo umount -l "$MNT_DIR"
}




mkdir -p "$DATA_DIR"

#prepare the kernel
download_kernel_and_tools
patch_kernel
compile_kernel





#prepare the images
download_image

RX_IMAGE_FILE="data/RX_$BASE_IMAGE"".img"
RX_INSTALL_SCRIPT="rx_install_script.sh"
patch_rpi_image "$RX_IMAGE_FILE" "$RX_INSTALL_SCRIPT"

TX_IMAGE_FILE="$DATA_DIR/TX_$BASE_IMAGE"".img"
TX_INSTALL_SCRIPT="tx_install_script.sh"
patch_rpi_image "$TX_IMAGE_FILE" "$TX_INSTALL_SCRIPT"

