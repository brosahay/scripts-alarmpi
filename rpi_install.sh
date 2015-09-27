#### ALARMpi INSTALL SCRIPT ####
#### @author : revosftw     ####
#### 	23- Jul - 2015 		####

#### VARIABLES ####
default_user="alarm"
torrent_path="/mnt/share"
drive_path="/dev/sda2"

###################

#!/bin/bash
#### CHANGE ROOT PASSWORD ####
passwd

#### UPDATE rPi AND INSTALL PACKAGES ####
pacman -Syu --noconfirm
pacman -S wget --noconfirm --needed

#### PACMAN ####
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#XferCommand = \/usr\/bin\/wget --passive-ftp -c -O %o %u/XferCommand = \/usr\/bin\/wget --passive-ftp -c -O -q --show-progress \x27%o\x27 \x27%u\x27/' /etc/pacman.conf

#### UPDATE rPi AND INSTALL PACKAGES ####
#pacman -S polkit --noconfirm
pacman -S base-devel vim zsh wget libnewt --noconfirm --needed
pacman -S python2 python2-pip python2-lxml --noconfirm --needed
pip2 install mitmproxy
pacman -S filesystem nfs-utils autofs diffutils --noconfirm --needed
#AUDIO
#pacman -S alsa-utils alsa-firmware alsa-lib alsa-plugins
#Wi-Fi
pacman -S dialog wpa_supplicant --noconfirm --needed
#OPTIONAL
pacman -S packer ntp transmission-cli git htop ntfs-3g --noconfirm --needed

#### ADD A NEW USER AS pi ####
useradd -m -g users -G wheel -s /bin/zsh $default_user
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chfn $default_user
passwd $default_user

#### MOUNT POINTS ####
mkdir -p $torrent_path

#### Wi-Fi SETUP ####
wifi-menu -o

#### OVERCLOCKING ####
echo -e "##OVERCLOCKING##\narm_freq=800\narm_freq_min=100\ncore_freq=300\ncore_freq_min=75\nsdram_freq=400\nover_voltage=0" >> /boot/config.txt

#### SCRIPTS ####
cd /usr/bin
wget https://raw.githubusercontent.com/revosftw/alarmpi_box/master/raspi-config
chmod +x raspi-config

#### YAOURT ####
cd /tmp
su $default_user
wget https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz
tar -xvzf package-query.tar.gz
cd package-query
makepkg -si
cd ..
wget https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz
tar -xvzf yaourt.tar.gz
cd yaourt
makepkg -si

#### START UPS ####
#sudo systemctl enable transmission
#sudo systemctl enable smbd