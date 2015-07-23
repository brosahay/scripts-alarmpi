#!/bin/bash
if grep -qs '/mnt/share' /proc/mounts; then
	transmission-daemon -g /mnt/share/.config/transmission-daemon
	sleep 2
	echo "Transmission Started"
else
	echo "No Hard Drive Mounted"
fi
