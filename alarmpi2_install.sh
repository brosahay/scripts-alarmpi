#### ALARMpi SD CARD INSTALL SCRIPT ####
#### 		@author : revosftw		####
#### 			23- Jul - 2015 		####

#!/bin/sh

[ "$UID" -eq 0 ] || exec sudo sh "$0" "$@"

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
if
 ls|grep -qs 'ArchLinuxARM-rpi-2'; then
	echo -e "Using old copy of ArchLinuxARM"
else
	wget -q --show-progress -c http://archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz
fi

echo -e "Extracting image to SD CARD"
sudo su -c 'bsdtar -xpf ArchLinuxARM-rpi-2-latest.tar.gz -C root'
sudo su -c 'sync'

echo -e "Finalizing boot partition"
sudo mv root/boot/* boot
sudo umount boot root
sudo su -c "rm -rf boot root"
echo -e "SD CARD ready to boot with ArchLinuxARM."
echo -e "Default SSH credentials:\n\t\tusername:alarm\n\t\tpassword:alarm\n\t\troot-password: root"