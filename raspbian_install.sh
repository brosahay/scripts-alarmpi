#!/bin/bash

######################################################################
#
#  Copyright (c) 2018 revosftw (https://github.com/revosftw)
#
######################################################################

RELEASE=" > /dev/null 2>&1"
DEBUG=""

DFLAG=$DEBUG

function pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

function updateSystem(){
  echo -e "Please wait updating system."
  sudo apt-get update ${DFLAG}
  sudo apt-get --yes upgrade ${DFLAG}
}

function installPackage(){
  sudo apt-get --yes install $@ ${DFLAG}
  sudo apt-get --yes autoclean ${DFLAG}
}

function configureWireless(){
  local wifiDevice=wlan0
  local accessPointNames
  local accessPointPassword
  local networkTemplate

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

function installBarebone(){
  updateSystem
  installPackage htop ntfs-3g
}
