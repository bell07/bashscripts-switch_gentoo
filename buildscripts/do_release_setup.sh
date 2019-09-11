#!/bin/bash
## This script is called from build release in qemu chroot
update-boot.scr.sh

echo '* Configure services with parallel start'

sed -i 's/#rc_parallel="NO"/rc_parallel="YES"/g' etc/rc.conf

rc-update add reboot2hekate boot

rc-update add dhcpcd default
rc-update add sshd default
ln -s net.lo /etc/init.d/net.wlp1s0
rc-update add wpa_supplicant default
ln -s net.lo /etc/init.d/net.usb0
rc-update add net.usb0 default

rc-update add bluetooth default

rc-update add dbus default
rc-update add xdm default
sed -i 's/^DISPLAYMANAGER=.*/DISPLAYMANAGER="lightdm"/g' /etc/conf.d/xdm

echo "Set hostname to 'nintendo-switch'"
echo 'hostname="nintendo-switch"' > /etc/conf.d/hostname

echo "  Write mmcblk0p1 as /mnt/sdcard1 to fstab"
mkdir /mnt/sdcard1
echo '/dev/mmcblk0p1		/mnt/sdcard1	vfat		noauto,noatime		0 1' >> /etc/fstab

echo "  Write mmcblk0p2 as root to fstab"
echo '/dev/mmcblk0p2		/		ext4		noatime		0 1' >> /etc/fstab


echo '** Configure users'

echo 'Set root password to "switch"'
echo -e "switch\nswitch\nswitch" | passwd root
echo 'create new user "switch" with "switch"'
useradd -m switch -G wheel,video

echo -e "switch\nswitch\nswitch" | passwd switch


echo 'keyboard=onboard' >> /etc/lightdm/lightdm-gtk-greeter.conf

echo "  Apply kernel modules configuration"
cat >> /etc/conf.d/modules << EOL

## Enable this module if you like to connect trough usb network IP 192.168.76.1
#modules="g_ncm"

# By default the nintendo open serial terminal on USB
modules="g_serial"
EOL

echo "set USB-IP to 192.168.76.1/24"
echo 'config_usb0="192.168.76.1/24"' >> /etc/conf.d/net

echo 'f0:12345:respawn:/sbin/agetty 115200 ttyGS0 vt100' >> /etc/inittab
