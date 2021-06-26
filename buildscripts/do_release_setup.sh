#!/bin/bash
## This script is called from build release in qemu chroot

DEFAULT_PASSWORD="Gentoo!Switch"

echo '* Enable services'

rc-update add connman default
rc-update add bluetooth default
rc-update add sshd default
rc-update add dbus default
rc-update add display-manager default
rc-update add joycond default

echo '* Configure services'
echo 'Enable rc_parallel="YES"'
sed -i 's/#rc_parallel="NO"/rc_parallel="YES"/g' /etc/rc.conf

echo "Set hostname to 'nintendo-switch'"
echo 'hostname="nintendo-switch"' > /etc/conf.d/hostname

echo "Write mmcblk0p2 as root to fstab"
echo '/dev/mmcblk0p2		/		ext4		noatime		0 1' >> /etc/fstab

echo '* Configure users'
echo 'Set root password to "'"$DEFAULT_PASSWORD"'"'
echo -e 'switch\n'"DEFAULT_PASSWORD"\n"DEFAULT_PASSWORD" | passwd root

echo 'create new user "switch" with password "'"$DEFAULT_PASSWORD"'"'
useradd -m switch -G audio,input,users,video,wheel
echo -e 'switch\n'"DEFAULT_PASSWORD"\n"DEFAULT_PASSWORD"  | passwd switch

echo '* Enable and configure lightdm'
sed -i 's/^DISPLAYMANAGER=.*/DISPLAYMANAGER="lightdm"/g' /etc/conf.d/display-manager

echo 'keyboard=onboard' >> /etc/lightdm/lightdm-gtk-greeter.conf
#sed -i 's!#allow-user-switching=.*!allow-user-switching=true!g' /etc/lightdm/lightdm.conf
#sed -i 's!#display-setup-script=.*!display-setup-script=/usr/bin/dock-script.sh!g' /etc/lightdm/lightdm.conf
sed -i 's!#autologin-user=.*!autologin-user=switch!g' /etc/lightdm/lightdm.conf
sed -i 's!#autologin-session=.*!autologin-session=xfce!g' /etc/lightdm/lightdm.conf
