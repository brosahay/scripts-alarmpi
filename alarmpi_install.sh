# alarmpi install script
#!/bin/sh

RED='\033[0;41;30m'
STD='\033[0;0;39m'

function pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

function change_root_password(){
	echo -e "Enter new root password:" 
	passwd
}

function install_wifi(){
	echo -e "Installing WiFi related packages"
	pacman -S dialog wpa_supplicant --noconfirm --needed > /dev/null 2>&1
	echo -e "Do you want to setup WiFi now? [Y/N]"
	read response
	if echo "$response" | grep -iq "^y"; then
		wifi-menu -o
	fi
	echo -e "WiFi installed"
}

function install_audio(){
	echo -e "Installing audio realted packages"
	pacman -S alsa-utils alsa-firmware alsa-lib alsa-plugins > /dev/null 2>&1
	echo -e "Audio installed"
}

function install_base(){
	echo -e "Updating package databases"
	pacman -Syu --noconfirm > /dev/null 2>&1
	echo -e "Installing base packages"
	pacman --noconfirm --needed -S base-devel vim zsh wget libnewt diffutils htop ntp packer > /dev/null 2>&1
	update_pacman
	echo -e "Installing filesystems"
	pacman --noconfirm --needed -S filesystem nfs-utils autofs ntfs-3g > /dev/null 2>&1
}

function install_python2(){
	echo -e "Installing python2"
	pacman --noconfirm --needed -S python2 python2-pip python2-lxml > /dev/null 2>&1
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
	pacman -S transmission-cli > /dev/null 2>&1
	usermod -aG users transmission
	lsblk
	echo -e "Select the drive to be used: (ex:/dev/sda1,\e[1m/dev/sda2\e[21m)"
	read external_drive
	external_drive=${external_drive:="/dev/sda2"}
	echo -e "Provide torrent download folder (ex: /media/data,\e[1m/mnt/downloads\e[21m):"
	read torrent_download_folder
	torrent_download_folder=${torrent_download_folder:="/media/data"}
	mkdir -p $torrent_download_folder
	make_mount
}

function make_mount(){
	#what="$external_drive"
	#where="$torrent_download_folder"
	#partition_type=blkid -s TYPE "$what" | grep -o '"[^"]*"' | sed 's/\"//g'
	echo -e "[Unit]
			 \nDescription=xHD mount script
			 \n
			 \n[Mount]
			 \nWhat=/dev/sda2
			 \nWhere=/media/data
			 \nType=ntfs-3g
			 \nOptions=defaults" > /etc/systemd/system/media-data.mount
}

function update_pacman(){
	echo -e "Setting options for pacman"
	sed -i 's/#Color/Color/' /etc/pacman.conf
	sed -i 's/#XferCommand = \/usr\/bin\/wget --passive-ftp -c -O %o %u/XferCommand = \/usr\/bin\/wget --passive-ftp -c -q --show-progress -O \x27%o\x27 \x27%u\x27/' /etc/pacman.conf
}


function update_user_config(){
	local user
	read -p "Enter username[\e[1malarm\e[21m]:"
	user=${user:="alarm"}
	usermod -aG users,lp,network,video,audio,storage "$user"
	chfn "$user"
	passwd "$user"
}

function overclock_raspberrypi(){
	echo -e "##OVERCLOCKING##
			 \narm_freq=800
			 \narm_freq_min=100
			 \ncore_freq=300
			 \ncore_freq_min=75
			 \nsdram_freq=400
			 \nover_voltage=0" >> /boot/config.txt
}

function move_root(){
	$newroot=/mnt/newroot
	sudo mkdir $newroot
	lsblk
	echo -e "Choose new root (ex: \e[1m/dev/sda1\e[21m):"
	read newrootdevice
	newroot=${newrootdevice:=/dev/sda1}
	echo -e "Formatting new root"
	mkfs.ext4 -L "armroot_overlay" $newrootdevice
	echo -e "Mounting new root"
	mount $newrootdevice $newroot
	rsync -avxS / $newroot > ~/.newroot.log
	cp /boot/cmdline.txt /boot/cmdline.txt.bak
	sed -i /boot/cmdline.txt 's/root=\/dev\/mmcblk0p2/root=${newrootdevice}/'
	sed -i /boot/cmdline.txt 's/elevator=noop//'
}

function show_options(){
	echo -e "\e[1m[1]\e[21mSetup Raspberry Pi"
	echo -e "\e[1m[2]\e[21mInstall Transmission"
	echo -e "\e[1m[3]\e[21mInstall Python2"
	echo -e "\e[1m[8]\e[21mMove Root to XHD"
	echo -e "\e[1m[9]\e[21mOverclock the Pi"
	echo -e "\e[1m[0]\e[21mExit"
}

function read_options(){
	local choice
	read -p "Enter choice:" choice
	case $choice in
		1)change_root_password;install_base;install_wifi;update_user_config;;
		2)install_transmission_seedbox;;
		3)install_python2;;
		8)move_root;;
		9)overclock_raspberrypi;;
		0)exit 0;;
		*)echo -e "$RED \e[1mERROR:\e[21m $STD INVALID SELECTION" && sleep 2
	esac	
}

trap '' SIGINT SIGQUIT SIGTSTP

#main function
[ "$UID" -eq 0 ] || exec su --command="sh $0 $@"

while true;
do
	show_options
	read_options
done