#!/bin/bash

######################################################################
#
#  Copyright (c) 2017 revosftw (https://github.com/revosftw)
#
######################################################################
if grep -qs '/mnt/share' /proc/mounts; then
	transmission-daemon -g /mnt/share/.config/transmission-daemon
	sleep 2
	echo "Transmission Started"
else
	echo "No Hard Drive Mounted"
fi
