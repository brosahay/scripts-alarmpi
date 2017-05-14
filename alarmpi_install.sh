# alarmpi install script
#!/bin/sh
function change_root_password(){
	passwd "$1"
}

function install_wifi(){
	echo -e "Installing WiFi related packages"
	pacman -S dialog wpa_supplicant --noconfirm --needed
	echo -e "Do you want to setup WiFi now? [Y/N]"
	read response
	if echo "$response" | grep -iq "^y"; then
		wifi-menu -o
	fi
	echo -e "WiFi installed"
}

function install_audio(){
	echo -e "Installing audio realted packages"
	pacman -S alsa-utils alsa-firmware alsa-lib alsa-plugins
	echo -e "Audio installed"
}

function install_base(){
	echo -e "Updating package databases"
	pacman -Syu --noconfirm
	echo -e "Installing base packages"
	pacman --noconfirm --needed -S base-devel vim zsh wget libnewt diffutils htop ntp packer
	update_pacman
	echo -e "Installing filesystems"
	pacman --noconfirm --needed -S filesystem nfs-utils autofs ntfs-3g
}

function install_python2(){
	echo -e "Installing python2"
	pacman --noconfirm --needed -S python2 python2-pip python2-lxml
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
	pacman -S transmission-cli
	usermod -aG users transmission
	lsblk
	echo -e "Select the drive to be used: (ex:/dev/sda1,/dev/sda2)"
	read external_drive
	external_drive = {external_drive:="/dev/sda2"}
	echo -e "Provide torrent download folder (ex: /media/data,\e[1m/mnt/downloads\e[21m):"
	read torrent_download_folder
	torrent_download_folder={torrent_download_folder:="/media/data"}
	mkdir -p $torrent_download_folder
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
	usermod -aG users,lp,network,video,audio,storage "$1"
	chfn "$1"
	passwd "$1"
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
	echo -e "Choose new root (ex: /dev/sda1):"
	read newrootdevice
	newroot={newrootdevice:=/dev/sda1}
	echo -e "Formatting new root"
	mkfs.ext4 -L "armroot_overlay" $newrootdevice
	echo -e "Mounting new root"
	mount $newrootdevice $newroot
	rsync -axS / $newroot
	cp /boot/cmdline.txt /boot/cmdline.txt.bak
	sed -i /boot/cmdline.txt 's/root=\/dev\/mmcblk0p2/root=${newrootdevice}/'
	sed -i /boot/cmdline.txt 's/elevator=noop//'
}

function show_options(){
	echo -e "[1]Setup Raspberry Pi"
	echo -e "[2]Install Transmission"
	echo -e "[3]Move Root to XHD"
	echo -e "[4]Exit"
}

function read_options(){
	local choice
	read -p "Enter choice:" choice
	case $choice in
		1)install_base;install_wifi;install_python2;;
		2)install_transmission_seedbox;;
		3)move_root;;
		4)exit 0;;
		*)echo -e "INVALID SELECTION" && sleep 2
	esac	
}

#main function
[ "$UID" -eq 0 ] || exec su --command="sh $0 $@"

while true;
do
	show_options
	read_options
done