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

function configureWireless(){
	echo -e "Searching for Access Points"
  local accessPointNames
  accessPointNames = sudo iwlist wlan0 scan | awk -F ':' '/ESSID:/ {print $2;}'
  networkTemplate = 'network={\n\tssid="$accessPointName"\n\tpsk="$accessPointPassword"\n}'
  local accessPointInput
  select accessPointInput in accessPointNames;
  read -p "Select Access Point:" accessPointInput
}
