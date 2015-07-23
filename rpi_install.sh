#### ALARMpi INSTALL SCRIPT ####
#### @author : revosftw     ####
#### 	23- Jul - 2015 		####

#### VARIABLES ####
default_user="pi"
torrent_path="/mnt/share"
drive_path="/dev/sda2"

###################

#!/bin/bash
#### CHANGE ROOT PASSWORD ####
passwd

#### PACMAN ####
sed -i 's/#Color/Color/' /etc/pacman.conf

#### UPDATE rPi AND INSTALL PACKAGES ####
pacman -Syu --noconfirm
pacman -S linux-raspberrypi-latest base-devel --noconfirm
pacman -S core/dnsutils extra/python2 extra/python2-pip extra/python2-lxml vim zsh wget polkit --noconfirm
pip2 install mitmproxy
pacman -S ntp filesystem transmission-cli nfs-utils htop autofs git diffutils libnewt ntfs-3g --noconfirm
#AUDIO
#pacman -S alsa-utils alsa-firmware alsa-lib alsa-plugins

#### ADD A NEW USER AS pi ####
useradd -m -g users -G wheel,storage -s /bin/zsh $default_user
usermod -aG storage $default_user
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chfn $default_user
passwd $default_user

#### YAOURT ####
cd /tmp
wget https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz
tar -xvzf package-query.tar.gz
cd package-query
makepkg -si
cd ..
wget https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz
tar -xvzf yaourt.tar.gz
cd yaourt
makepkg -si

#### MOUNT POINTS ####
mkdir -p $torrent_path
#mount $drive_path $torrent_path
#echo -e "${drive_path}\t${torrent_path}\tntfs-3g\tdefaults\t0\t0" >> /etc/fstab

#### Wi-Fi SETUP ####
pacman -S dialog wpa_supplicant
wifi-menu

#### OVERCLOCKING ####
echo -e "##OVERCLOCKING##\narm_freq=800\narm_freq_min=100\ncore_freq=300\ncore_freq_min=75\nsdram_freq=400\nover_voltage=0" >> /boot/config.txt

#### SCRIPTS ####
cd /home/$default_user
wget https://github.com/revosftw/alarmpi_box/blob/master/rpi_trans_start.sh
chmod +x rpi_trans_start.sh

mkdir -p /home/$default_user/.config/systemd/user
#echo >>/home/$default_user/.config/systemd/user/rpi_transmission.service
