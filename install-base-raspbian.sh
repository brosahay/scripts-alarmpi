#!/bin/bash

######################################################################
#
#  Copyright (c) 2018 revosftw (https://github.com/revosftw)
#
######################################################################

RELEASE=" > /dev/null 2>&1"
DEBUG=""
DFLAG=$DEBUG
function pause() {
  read -p "Press [Enter] key to continue..." fackEnterKey
}

function updateSystem() {
  echo -e "Please wait updating system."
  sudo apt-get update ${DFLAG}
  sudo apt-get --yes upgrade ${DFLAG}
}

function installPackage() {
  sudo apt-get --yes install $@ ${DFLAG}
}

function installBarebone() {
  updateSystem
  installPackage htop ntfs-3g
}

function configureTimezone() {
  echo -e "Setting timezone"
	sudo timedatectl set-local-rtc 0
  local timezone
	read -p "Enter a timezone(ex. Asia/Kolkata):" timezone
	timezone=${timezone:="Asia/Kolkata"}
	echo -e "$timezone" | sudo tee /etc/timezone
  sudo systemctl stop ntpd.service
  sudo systemctl enable ntpd.service
	sudo systemctl start ntpd.service
}

function configureWireless() {
  local wifiDevice=wlan0
  local accessPointNames
  local accessPointPassword

  echo -e "Searching for Access Points"
  accessPointNames=$(sudo iwlist $wifiDevice scan | awk -F ':' '/ESSID:/ {print $2;}' | sed 's/"//g')

  #Set IFS options
  local IFS=$'\n'

  #Set PS3 prompt
  local PS3="Select Access Point: "
  local accessPointInput

  select accessPointInput in $accessPointNames EXIT;
  do
    case $accessPointInput in
      exit)
      break;;
      *)
      echo "Enter password for $accessPointInput: "
      read -s accessPointPassword
      wpa_passphrase $accessPointInput "$accessPointPassword" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf ${DFLAG}
      echo -e "Configured $accessPointInput"
      wpa_cli -i $wifiDevice reconfigure ${DFLAG}
      ;;
    esac
  done
}

function configureHostname() {
  local hostname
	read -p "Enter hostname(ex. alarmpi):" hostname
	hostname=${hostname:=alarmpi}
	sudo hostnamectl set-hostname $hostname
}

function configureNewUser() {
  local username
	read -p "Enter username[pi]:" user
	username=${username:="pi"}
	getent passwd $username > /dev/null
	if [ $? -eq 0 ]; then
		updateUserConfiguration $username
	else
		useradd -m $username
		updateUserConfiguration $username
	fi
}

function updateUserConfiguration() {
  local username=$1
	chfn "$username"
	passwd "$username"

  local response
  read -p "Grant root priviledges to $username?" response
	if echo "$response" | grep -iq "^Y"; then
		addRootPriviledgesUser $username
	fi

}

function addRootPriviledgesUser() {
  local username=$1
  echo -e "Adding root priviledges to $username"
  echo -e "$username ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
}

function deleteOldUser() {
  sudo userdel $1
  sudo rm -rf /home/${1}
}

function addRootPriviledgesGroup() {
  local groupname=$1
  echo -e "Adding root priviledges to $groupname"
  echo -e "%$groupname ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
}

function configureBarebone() {
  echo -e "Enter new root password: "
	sudo passwd

  #Set up timezone
  configureTimezone

  #Set a new hostname
  configureHostname

  #Setup a new user
  configureNewUser

  #Setup WiFi
  configureWireless

  #clean aptitude cache
  sudo apt-get --yes autoclean ${DFLAG}
}

function installWiringPi() {
  git clone git://git.drogon.net/wiringPi /opt/wiringpi
  sh /opt/wiringpi/build
  gpio -v
  gpio readall
}

function installZSH() {
  echo -e "Installing ZSH"
  installPackage zsh
  echo -e "Installing grml-zsh"
	curl -L "http://git.grml.org/f/grml-etc-core/etc/zsh/zshrc" --output /home/"$1"/.zshrc  ${DFLAG}
	curl -L "http://git.grml.org/f/grml-etc-core/etc/skel/.zshrc" --output /home/"$1"/.zshrc.local ${DFLAG}
	chown /home/"$1"/.zshrc* "$1:$1"
	sudo usermod -s /bin/zsh "$1"
}

function newRootfs() {
  installPackage rsync
  newroot="/mnt/newroot"
	sudo mkdir ${newroot}
	lsblk
	echo -e "Choose new root (ex: \e[1m/dev/sda1\e[21m):"
	read newrootdevice
	newrootdevice=${newrootdevice:="/dev/sda1"}
	echo -e "Formatting new root"
	mkfs.ext4 -L "armroot_overlay" ${newrootdevice}
	echo -e "Mounting new root"
	sudo mount ${newrootdevice} ${newroot}
	sudo rsync -avxS / ${newroot}
	cp /boot/cmdline.txt /boot/cmdline.txt.bak
	sudo sed "s/root=\/dev\/mmcblk0p2/root=${newrootdevice}/" -i /boot/cmdline.txt
	sudo sed 's/elevator=noop//' -i /boot/cmdline.txt
	sudo umount ${newroot}
  sudo rm -rf ${newroot}
}

function checkMountPoint() {
    if grep -qs '$1' /proc/mounts; then
        echo "It's mounted."
    else
        echo "It's not mounted."
    fi
}

function showOptions() {
  echo -e "######Raspbian Installer######"
  echo -e "\e[1m[1]\e[21m setup raspberry pi"
	# echo -e "\e[1m[2]\e[21mInstall Transmission"
	# echo -e "\e[1m[3]\e[21mInstall Python2"
	# echo -e "\e[1m[4]\e[21mInstall Raspi-Config"
	echo -e "\e[1m[8]\e[21m move rootfs to external storage"
	echo -e "\e[1m[0]\e[21m exit"
}

function readOptions(){
	local choice
	read -p "Enter choice:" choice
	case $choice in
		1)installBarebone;configureBarebone;;
		2);;
		3);;
		4);;
		8)newRootfs;;
		9);;
		0)exit 0;;
		*)echo -e "$RED \e[1mERROR:\e[21m $STD INVALID SELECTION" && sleep 2;;
	esac
}

while true;
do
	showOptions
  readOptions
done

# declare -a options=("setup raspberry pi" "install transmission" "install python 2" "install zsh shell" "move rootfs to external storage") exit
# IFS=$'\n'
# select option in options;
# do
#   echo "$option"
# done
