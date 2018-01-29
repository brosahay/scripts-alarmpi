#!/bin/bash

######################################################################
#
#  Copyright (c) 2017 revosftw (https://github.com/revosftw)
#
######################################################################

RED='\033[0;41;30m'
STD='\033[0;0;39m'

RELEASE=" > /dev/null 2>&1"
DEBUG=""

DFLAG=$DEBUG

function pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

function install_wifi(){
	echo -e "Installing WiFi related packages"
	pacman -S dialog wpa_supplicant wireless_tools iw crda lshw --noconfirm --needed ${DFLAG}
	echo -e "WiFi installed"
}

function install_audio(){
	echo -e "Installing audio realted packages"
	pacman -S alsa-utils alsa-firmware alsa-lib alsa-plugins ${DFLAG}
	echo -e "Audio installed"
}

function install_base(){
	echo -e "Updating package databases"
	pacman --noconfirm --needed -Syu ${DFLAG}
	pacman --noconfirm --needed -Sy pacman ${DFLAG}
	pacman-key --init ${DFLAG}
	pacman --noconfirm --needed -S archlinux-keyring ${DFLAG}
	pacman-key --populate archlinux ${DFLAG}
	pacman --noconfirm --needed -Syu --ignore filesystem ${DFLAG}
	pacman --noconfirm --needed -S filesystem --force ${DFLAG}
	echo -e "Installing base packages"
	pacman --noconfirm --needed -S base-devel vim wget libnewt diffutils htop ntp packer ${DFLAG}
	echo -e "Installing filesystems"
	pacman --noconfirm --needed -S filesystem nfs-utils autofs ntfs-3g ${DFLAG}
}

function install_zsh(){
	echo -e "Installing ZSH"
	pacman --noconfirm --needed -S zsh ${DFLAG}
	echo -e "Installing grml-zsh"
	curl -L "http://git.grml.org/f/grml-etc-core/etc/zsh/zshrc" --output /home/"$1"/.zshrc  ${DFLAG}
	curl -L "http://git.grml.org/f/grml-etc-core/etc/skel/.zshrc" --output /home/"$1"/.zshrc.local ${DFLAG}
	chown /home/"$1"/.zshrc* "$1:$1"
	usermod -s /bin/zsh "$1"
}

function install_raspiconfig(){
	echo -e "Downloading Raspi-Config"
	curl -L https://raw.githubusercontent.com/revosftw/alarmpi_box/master/raspi-config --output /usr/bin/raspi-config
	chmod +x /usr/bin/raspi-config;
	echo -e "Installed Raspi-Config"
}

function install_python2(){
	echo -e "Installing python2"
	pacman --noconfirm --needed -S python2 python2-pip python2-lxml ${DFLAG}
	pip2 install mitmproxy
}

function install_yaourt(){
	cd /tmp
	#su $default_user
	wget https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz
	tar -xvzf package-query.tar.gz
	cd package-query
	makepkg -si
	cd ..
	wget https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz
	tar -xvzf yaourt.tar.gz
	cd yaourt
	makepkg -si
}

function install_transmission_seedbox(){
	echo -e "Installing Transmission"
	pacman --noconfirm --needed -S transmission-cli ${DFLAG}
	usermod -aG users transmission

	lsblk
	echo -e "Select the drive to be used: (ex:/dev/sda1,\e[1m/dev/sda2\e[21m)"
	read external_drive
	external_drive=${external_drive:="/dev/sda2"}

	echo -e "Provide torrent download folder (ex: \e[1m/media/data\e[21m,/mnt/downloads):"
	read torrent_download_folder
	torrent_download_folder=${torrent_download_folder:="/media/data"}
	mkdir -p $torrent_download_folder

	make_mount
}

function install_wiringPi(){
	git clone git://git.drogon.net/wiringPi /opt/wiringpi
	sh /opt/wiringpi/build
	gpio -v
	gpio readall
}

function make_mount(){
	what="$external_drive"
	where="$torrent_download_folder"
	partition_type=sudo blkid -s TYPE "$what" | grep -o '"[^"]*"' | sed 's/\"//g'
	echo -e "[Unit]\nDescription=xHD mount script\n\n[Mount]\nWhat=$what\nWhere=$where\nType=$partition_type\nOptions=defaults,gid=users,dmask=002,fmask=002" > /etc/systemd/system/media-data.mount
}

function basic_setup(){
	echo -e "Enter new root password:"
	passwd

	echo -e "Setting timezone"
	timedatectl set-local-rtc 0
	local timezone
	read -p "Enter a timezone(ex. Asia/Kolkata):" timezone
	timezone=${timezone:="Asia/Kolkata"}
	echo -e "$timezone" > /etc/timezone
	systemctl enable ntpd.service
	systemctl start ntpd.service

	echo -e "Setting options for pacman"
	sed -i '/Color/s/^#//' /etc/pacman.conf
	sed -i 's/#XferCommand = \/usr\/bin\/wget --passive-ftp -c -O %o %u/XferCommand = \/usr\/bin\/wget --passive-ftp -c -q --show-progress -O \x27%o\x27 \x27%u\x27/' /etc/pacman.conf

	echo "Root Priviledges"
	sed -i '/%wheel ALL=(ALL) NOPASSWD: ALL/s/^#//' /etc/sudoers

	local hostname
	read -p "Enter hostname(ex. alarmpi):" hostname
	hostname=${hostname:=alarmpi}
	hostnamectl set-hostname $hostname

	local user
	#userdel alarm
	read -p "Enter username[pi,alarm]:" user
	user=${user:="pi"}
	getent passwd $user > /dev/null
	if [ $? -eq 0 ]; then
		update_user_config $user
	else
		useradd -m $user
		update_user_config $user
	fi

	local response;
	read -p "Install zsh?" response
	if echo "$response" | grep -iq "^y"; then
		install_zsh $user
	fi

	read -p "Do you want to setup WiFi now?" response
	if echo "$response" | grep -iq "^y"; then
		wifi-menu -o
	fi

	pacman -Scc
}

function update_user_config(){
	local user=$1
	#usermod -aG wheel,rvm,sers,users,lp,network,video,audio,storage
	usermod -g users -aG wheel,lp,network,video,audio,storage "$user"
	chfn "$user"
	passwd "$user"
}

function overclock_raspberrypi(){
	echo -e "##OVERCLOCKING##
			 arm_freq=800
			 arm_freq_min=100
			 core_freq=300
			 core_freq_min=75
			 sdram_freq=400
			 over_voltage=0" >> /boot/config.txt
}

function move_root(){
	newroot="/mnt/newroot"
	sudo mkdir "$newroot"
	lsblk
	echo -e "Choose new root (ex: \e[1m/dev/sda1\e[21m):"
	read newrootdevice
	newrootdevice=${newrootdevice:="/dev/sda1"}
	echo -e "Formatting new root"
	mkfs.ext4 -L "armroot_overlay" $newrootdevice
	echo -e "Mounting new root"
	mount "$newrootdevice" "$newroot"
  pacman --noconfirm --needed -S rsync
	rsync -avxS --info=progress2 exclude="$newroot" / $newroot
	cp /boot/cmdline.txt /boot/cmdline.txt.bak
	sed 's/root=\/dev\/mmcblk0p2/root=${newrootdevice}/' -i /boot/cmdline.txt
	sed 's/elevator=noop//' -i /boot/cmdline.txt
	umount "$newroot"
}

function show_options(){
	echo -e "\e[1m[1]\e[21mSetup Raspberry Pi"
	echo -e "\e[1m[2]\e[21mInstall Transmission"
	echo -e "\e[1m[3]\e[21mInstall Python2"
	echo -e "\e[1m[4]\e[21mInstall Raspi-Config"
	echo -e "\e[1m[8]\e[21mMove Root to XHD"
	echo -e "\e[1m[9]\e[21mOverclock the Pi"
	echo -e "\e[1m[0]\e[21mExit"
}

function read_options(){
	local choice
	read -p "Enter choice:" choice
	case $choice in
		1)install_base;install_wifi;basic_setup;;
		2)install_transmission_seedbox;;
		3)install_python2;;
		4)install_raspiconfig;;
		8)move_root;;
		9)overclock_raspberrypi;;
		0)exit 0;;
		*)echo -e "$RED \e[1mERROR:\e[21m $STD INVALID SELECTION" && sleep 2
	esac
}
#trap '' SIGINT SIGQUIT SIGTSTP
#main function
[ "$UID" -eq 0 ] || exec su --command="sh $0 $@"

while true;
do
	show_options
	read_options
done
