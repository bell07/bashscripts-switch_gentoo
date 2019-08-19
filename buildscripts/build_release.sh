#!/bin/sh
CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"

TARGET_DIR="$PROJ_DIR"/out/release

echo "----- Step 1. Copy stage to release dir"
rm -Rf "$TARGET_DIR"
cp -a "$PROJ_DIR"/out/stage3 "$TARGET_DIR"

echo "----- Step 2. Configre system"
echo "  set Password to 'switch'"
sed -i 's|root:\*:|root:$6$NME85/IY7$tCY/YFXMOSyP.h6H/634bqI3aeNZZLCVpC7EsN32rA5xoiziCm6trzHzD7AfzdiGLK6nEHzSlWnzLB94IJKwK0:|g' "$TARGET_DIR"/etc/shadow

echo "  set hostname to 'nintendo-switch'"
echo 'hostname="nintendo-switch"' > "$TARGET_DIR"/etc/conf.d/hostname

echo "  Write /dev/mmcblk0p2 as root to fstab"
echo '/dev/mmcblk0p2		/		ext4		noatime		0 1' >> "$TARGET_DIR"/etc/fstab

echo "  Enable USB networking trough g_ncm usng IP 192.168.76.2/24"
echo 'modules="g_ncm"' >> "$TARGET_DIR"/etc/conf.d/modules

echo 'config_usb0="192.168.76.1/24"' >> "$TARGET_DIR"/etc/conf.d/net

echo "----- Step 3. Install world"
"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
FEATURES="-pid-sandbox buildpkg" emerge --usepkg --with-bdeps=n -uvDN --jobs=5 app-portage/nintendo-switch-release-meta @system @world

# Enable networking
rc-update add dhcpcd default
rc-update add sshd default
ln -s net.lo /etc/init.d/net.wlp1s0
rc-update add wpa_supplicant default
ln -s net.lo /etc/init.d/net.usb0
rc-update add net.usb0 default
update-boot.scr.sh
EOF

"$PROJ_DIR"/tools/system_chroot/chroot-umount.sh "$TARGET_DIR" # Be sure all is unmounted in case of errors

umount -v "$TARGET_DIR"/var/cache/binpkgs

echo "----- Step 4 cleanup and finalize"
rm -Rf "$TARGET_DIR"/var/tmp/portage
rm "$TARGET_DIR"/var/log/emerge.log
rm "$TARGET_DIR"/var/log/emerge-fetch.log
rm "$TARGET_DIR"/var/log/portage/elog/summary.log
rm -Rf "$TARGET_DIR"/var/cache/edb/binhost
rm "$TARGET_DIR"/etc/resolv.conf

echo "----- Step 5 create stage package --"
cd "$TARGET_DIR"
tar -czf ../switch-gentoo-release.tar.gz *

echo "----- Step 6 Build SDCARD --"
mkdir -p "$PROJ_DIR"/out/release_SD/gentoo
cd "$TARGET_DIR"/boot/
cp -a boot.scr coreboot.rom tegra210*.dtb vmlinuz* "$PROJ_DIR"/out/release_SD/gentoo
cd "$PROJ_DIR"/out/release_SD
zip -r ../switch-gentoo-boot.zip *
