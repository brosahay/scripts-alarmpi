#!/bin/bash

######################################################################
#                                                                    #
#    Copyright (c) 2017 revosftw (https://github.com/revosftw)       #
#                                                                    #
######################################################################

RED='\033[0;41;30m'
STD='\033[0;0;39m'

RELEASE=" > /dev/null 2>&1"
DEBUG=""

DFLAG=$DEBUG

function pause() {
    read -p "Press [Enter] key to continue..." fackEnterKey
}

function updateSystem() {
    echo -e "Updating System"
    pacman --noconfirm --needed -Syu ${DFLAG}
}

function installPackage() {
    pacman --noconfirm --needed -S $@ ${DFLAG}
}

function initializePacman() {
    pacman --noconfirm --needed -Sy pacman ${DFLAG}
    pacman-key --init ${DFLAG}
    installPackage archlinux-keyring
    pacman-key --populate archlinux ${DFLAG}
}

function configurePacman() {
    echo -e "Setting options for pacman"
    cp /etc/pacman.conf /etc/pacman.conf.bak
    sed -i '/Color/s/^#//' /etc/pacman.conf
    sed -i 's/#XferCommand = \/usr\/bin\/wget --passive-ftp -c -O %o %u/XferCommand = \/usr\/bin\/wget --passive-ftp -c -q --show-progress -O \x27%o\x27 \x27%u\x27/' /etc/pacman.conf
}

function installBarebone() {
    updateSystem
    initializePacman
    pacman --noconfirm --needed -Syu --ignore filesystem ${DFLAG}
    pacman --noconfirm --needed -S filesystem --force ${DFLAG}
    echo -e "Installing Base Packages"
    installPackage base-devel vim wget diffutils htop ntp packer
    echo -e "Install filesystems"
    installPackage filesystem nfs-utils autofs ntfs-3g
}

function installWireless() {
    echo -e "Installing WiFi packages"
    installPackage dialog wpa_supplicant wireless_tools iw crda lshw
}

function installAudio() {
    echo -e "Installing Audio packages"
    installPackage alsa-utils alsa-firmware alsa-lib alsa-plugins
}

function configureTimezone() {
    echo -e "Setting timezone"
    timedatectl set-local-rtc 0
    local timezone
    read -p "Enter a timezone(ex. Asia/Kolkata):" timezone
    timezone=${timezone:="Asia/Kolkata"}
    echo -e "$timezone" | tee /etc/timezone
    systemctl stop ntpd.service
    systemctl enable ntpd.service
    systemctl start ntpd.service
}

function configureHostname() {
    local hostname
    read -p "Enter hostname(ex. alarmpi):" hostname
    hostname=${hostname:=alarmpi}
    hostnamectl set-hostname $hostname
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

function addRootPriviledgesUser() {
    local username=$1
    echo -e "Adding root priviledges to $username"
    echo -e "$username ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers
}

function addRootPriviledgesGroup() {
    local groupname=$1
    echo -e "Adding root priviledges to $groupname"
    echo -e "%$groupname ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers
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

function deleteOldUser() {
    userdel $1
    rm -rf /home/${1}
}

function configureBarebone() {
    echo -e "Enter new root password: "
    passwd
    #Set up timezone
    configureTimezone
    #Set a new hostname
    configureHostname
    #Setup a new user
    configureNewUser
    #Setup WiFi
    configureWireless
    #clean pacman cache
    pacman --noconfirm -Scc
    pause
}

function installYaourt() {
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

function installZSH() {
    echo -e "Installing ZSH"
    installPackage zsh
    echo -e "Installing grml-zsh"
    curl -L "http://git.grml.org/f/grml-etc-core/etc/zsh/zshrc" --output /home/"$1"/.zshrc${DFLAG}
    curl -L "http://git.grml.org/f/grml-etc-core/etc/skel/.zshrc" --output /home/"$1"/.zshrc.local ${DFLAG}
    chown /home/"$1"/.zshrc* "$1:$1"
    usermod -s /bin/zsh "$1"
}

function installRaspiconfig() {
    echo -e "Downloading Raspi-Config"
    curl -L https://raw.githubusercontent.com/revosftw/alarmpi_box/master/raspi-config --output /usr/bin/raspi-config
    chmod +x /usr/bin/raspi-config;
    echo -e "Installed Raspi-Config"
}

function installPython2() {
    echo -e "Installing python2"
    installPackage python2 python2-pip python2-lxml
    pip2 install mitmproxy
}

function installWiringPi() {
    git clone git://git.drogon.net/wiringPi /opt/wiringpi
    sh /opt/wiringpi/build
    gpio -v
    gpio readall
}

function installTransmission() {
    echo -e "Installing Transmission"
    installPackage transmission-cli
    usermod -aG users transmission

    lsblk
    echo -e "Select the drive to be used: (ex:/dev/sda1,\e[1m/dev/sda2\e[21m)"
    read externalDrive
    externalDrive=${externalDrive:="/dev/sda2"}

    echo -e "Provide torrent download folder (ex: \e[1m/media/data\e[21m,/mnt/downloads):"
    read downloadFolder
    downloadFolder=${downloadFolder:="/media/data"}
    mkdir -p $downloadFolder

    createMountPoint externalDrive downloadFolder
}

function configureTransmission() {

}

function checkMountPoint() {
    if grep -qs '$1' /proc/mounts; then
        echo "It's mounted."
    else
        echo "It's not mounted."
    fi
}

function createMountPoint() {
    mountDevice=$1
    mountPoint=$2
    fileName=$(echo $mountPoint|sed 's\^[/]\\'|sed 's\[/]\-\')
    partitionType=$(blkid -s TYPE "$mountDevice" | grep -o '"[^"]*"' | sed 's/\"//g')
    echo -e "[Unit]
    \nDescription=xHD mount script
    \n
    \n[Mount]
    \nWhat=$mountDevice
    \nWhere=$mountPoint
    \nType=$partition_type
    \nOptions=defaults,gid=users,dmask=002,fmask=002" | tee /etc/systemd/system/${fileName}.mount
}


function overclockPi() {
    echo -e "##OVERCLOCKING##
    \n arm_freq=800
    \n arm_freq_min=100
    \n core_freq=300
    \n core_freq_min=75
    \n sdram_freq=400
    \n over_voltage=0" | tee -a /boot/config.txt
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
    mkfs.ext4 -L "armrootfs" ${newrootdevice}
    echo -e "Mounting new root"
    mount ${newrootdevice} ${newroot}
    rsync -avxS --info=progress2 exclude=${newroot} / ${newroot}
    cp /boot/cmdline.txt /boot/cmdline.txt.bak
    sed "s/root=\/dev\/mmcblk0p2/root=${newrootdevice}/" -i /boot/cmdline.txt
    sed "s/elevator=noop//" -i /boot/cmdline.txt
    umount ${newroot}
    rm -rf ${newroot}
}

function showOptions() {
    echo -e "\e[1m[1]\e[21mSetup Raspberry Pi"
    echo -e "\e[1m[2]\e[21mInstall Transmission"
    echo -e "\e[1m[3]\e[21mInstall Python2"
    echo -e "\e[1m[4]\e[21mInstall Raspi-Config"
    echo -e "\e[1m[8]\e[21mMove Root to XHD"
    echo -e "\e[1m[9]\e[21mOverclock the Pi"
    echo -e "\e[1m[0]\e[21mExit"
}

function readOptions() {
    local choice
    read -p "Enter choice:" choice
    case $choice in
        1)installBarebone;configureBarebone;;
        2)installTransmission;;
        3)installPython2;;
        4)installRaspiconfig;;
        8)newRootfs;;
        9)overclockPi;;
        0)exit 0;;
        *)echo -e "$RED \e[1mERROR:\e[21m $STD INVALID SELECTION" && sleep 2
    esac
}

#trap '' SIGINT SIGQUIT SIGTSTP
#main function
[ "$UID" -eq 0 ] || exec su --command="bash $0 $@"

while true;
do
    showOptions
    readOptions
done
