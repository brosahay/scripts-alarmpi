#!/bin/bash

######################################################################
#
#  Copyright (c) 2015 revosftw (https://github.com/revosftw)
#
######################################################################

#!/bin/sh

prepare_mmc () {
	lsblk
	echo -e "\nSelect the SD CARD (ex: /dev/sda):"
	read device
	partitions=($(lsblk "$device" | fgrep '─' | sed -E 's/^.+─(\w+).+$/\1/g'))

	echo -e "Unmount SD CARD"
	for eachPartion in "${partitions[@]}"
		do sudo umount -v "/dev/$eachPartion"
	done

	lsblk
	read -p "Press enter to continue"

	echo -e "Prepating SD CARD"
	(echo o; echo n; echo p;echo 1; echo ; echo +100M; echo t; echo c; echo n; echo p; echo 2; echo ; echo ;echo w)|sudo fdisk $device
	sudo fdisk -l $device

	echo -e "Preparing /boot partition"
	sudo mkfs.vfat -n "arm_boot" "/dev/${partitions[0]}"
	mkdir boot
	sudo mount "/dev/${partitions[0]}" boot
	echo -e "Mounted /boot partition"

	echo -e "Preparing /root partition"
	sudo mkfs.ext4 -L "arm_root" "/dev/${partitions[1]}"
	mkdir root
	sudo mount "/dev/${partitions[1]}" root
	echo -e "Mounted /root partition"	
}

download_archlinx () {
	echo -e "Searching for ArchLinuxARM-$1-latest.tar.gz"
	ls|grep -qs "ArchLinuxARM-$1"
	response=${response:="y"}
	if ls|grep -qsc "ArchLinuxARM-$1"; then
	echo -e "Found. Use old copy of ArchLinuxARM ? [\e[1mY\e[21m/n]"
	read response
	response=${response:="y"}
	fi
	if echo "$response" | grep -iq "^n"; then
		wget -q --show-progress --continue "http://archlinuxarm.org/os/ArchLinuxARM-$1-latest.tar.gz"
	fi
}

write_to_mmc () {
	echo -e "Extracting image to SD CARD"
	sudo su -c 'bsdtar -xpf ArchLinuxARM-$1-latest.tar.gz -C root'
	sudo su -c 'sync'

	echo -e "Finalizing boot partition"
	sudo mv root/boot/* boot
	sudo umount boot root
	sudo su -c "rm -rf boot root"
	echo -e "SD CARD ready to boot with ArchLinuxARM."
	echo -e "Default SSH credentials:\n\t\tusername:alarm\n\t\tpassword:alarm\n\t\troot-password: root"	
}

[ "$UID" -eq 0 ] || exec sudo sh "$0" "$@"
echo -e "\nSelect Raspberry Pi Version (ex: rpi rpi-2)[\e[1mrpi-2\e[21m]:"
read raspberrypi_version
raspberrypi_version=${raspberrypi_version:="rpi-2"}
download_archlinx $raspberrypi_version
prepare_mmc
write_to_mmc $raspberrypi_version