if grep -qs '/home/pi/disk' /proc/mounts; then
    echo "It's mounted."
else
    echo "It's not mounted."
fi
