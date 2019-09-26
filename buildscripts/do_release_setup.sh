#!/bin/bash
## This script is called from build release in qemu chroot
update-boot.scr.sh

echo '* Enable services'

rc-update add reboot2hekate boot
rc-update add wicd default
rc-update add bluetooth default
rc-update add joycond default
rc-update add sshd default
rc-update add dbus default
rc-update add xdm default

echo '* Configure services'
echo 'Enable rc_parallel="YES"'
sed -i 's/#rc_parallel="NO"/rc_parallel="YES"/g' /etc/rc.conf

echo "Set hostname to 'nintendo-switch'"
echo 'hostname="nintendo-switch"' > /etc/conf.d/hostname

echo '* Update fstab'
echo "Write mmcblk0p1 as /mnt/sdcard1 to fstab"
mkdir /mnt/sdcard1
echo '/dev/mmcblk0p1		/mnt/sdcard1	vfat		noauto,noatime		0 1' >> /etc/fstab

echo "Write mmcblk0p2 as root to fstab"
echo '/dev/mmcblk0p2		/		ext4		noatime		0 1' >> /etc/fstab


echo '* Configure users'
echo 'Set root password to "switch"'
echo -e "switch\nswitch\nswitch" | passwd root

echo 'create new user "switch" with "switch"'
useradd -m switch -G audio,input,plugdev,users,video,wheel
echo -e "switch\nswitch\nswitch" | passwd switch

echo '* Enable and configure lightdm'
sed -i 's/^DISPLAYMANAGER=.*/DISPLAYMANAGER="lightdm"/g' /etc/conf.d/xdm
mkdir -p /var/cache/lightdm/dmrc/
echo 'keyboard=onboard' >> /etc/lightdm/lightdm-gtk-greeter.conf
sed -i 's!#allow-user-switching=.*!allow-user-switching=true!g' /etc/lightdm/lightdm.conf
sed -i 's!#display-setup-script=.*!display-setup-script=/usr/bin/dock-script.sh!g' /etc/lightdm/lightdm.conf

echo '[Desktop]' > /var/cache/lightdm/dmrc/switch.dmrc
echo 'Session=xfce' >> /var/cache/lightdm/dmrc/switch.dmrc
echo 'Language=C.utf8' >> /var/cache/lightdm/dmrc/switch.dmrc

echo "* Apply kernel modules configuration"
cat >> /etc/conf.d/modules << EOL

## Enable this module if you like to connect trough usb network IP 192.168.76.1
#modules="g_ncm"

# By default the nintendo open serial terminal on USB
modules="g_serial"
EOL

echo 'f1:12345:respawn:/sbin/agetty 115200 ttyGS0 vt100' >> /etc/inittab

sed -i 's/#FastConnectable.*/FastConnectable = true/g' /etc/bluetooth/main.conf
sed -i 's/#AutoEnable.*/AutoEnable = true/g' /etc/bluetooth/main.conf
