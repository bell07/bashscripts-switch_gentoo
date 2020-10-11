#!/bin/bash
## This script is called from build release in qemu chroot

echo '* Enable services'

rc-update add reboot2hekate boot
rc-update add connman default
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

echo 'keyboard=onboard' >> /etc/lightdm/lightdm-gtk-greeter.conf
sed -i 's!#allow-user-switching=.*!allow-user-switching=true!g' /etc/lightdm/lightdm.conf
sed -i 's!#display-setup-script=.*!display-setup-script=/usr/bin/dock-script.sh!g' /etc/lightdm/lightdm.conf
sed -i 's!#autologin-user=.*!autologin-user=switch!g' /etc/lightdm/lightdm.conf
sed -i 's!#autologin-session=.*!autologin-session=xfce!g' /etc/lightdm/lightdm.conf

echo 'f1:12345:respawn:/sbin/agetty 115200 ttyGS0 vt100' >> /etc/inittab
