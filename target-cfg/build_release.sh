#!/bin/sh
CFG_DIR="$(dirname $0)"
PROJ_DIR="$(dirname "$CFG_DIR")"

TARGET_DIR="$PROJ_DIR"/out/release

RELEASE_PACKAGES="dev-vcs/git"                                  # To sync overlay
RELEASE_PACKAGES+=" app-editors/nano"                            # should not be replaced by VI
RELEASE_PACKAGES+=" net-misc/dhcpcd net-wireless/wpa_supplicant" # Wifi
RELEASE_PACKAGES+=" sys-kernel/nintendo-switch-l4t-kernel"       # Working kernel

echo "----- Step 1. Copy stage to release dir"
rm -Rf "$TARGET_DIR"
cp -a "$PROJ_DIR"/out/stage3 "$TARGET_DIR"

echo "----- Step 2. Set Password to 'switch'"
sed -i 's|root:\*:|root:$6$NME85/IY7$tCY/YFXMOSyP.h6H/634bqI3aeNZZLCVpC7EsN32rA5xoiziCm6trzHzD7AfzdiGLK6nEHzSlWnzLB94IJKwK0:|g' "$TARGET_DIR"/etc/shadow

echo "----- Step 3. Install world"
"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
FEATURES="-pid-sandbox buildpkg" emerge --usepkg --with-bdeps=n -uvDN --jobs=5 $RELEASE_PACKAGES @system @world

# Enable networking
rc-update add dhcpcd default
rc-update add sshd default
ln -s net.lo /etc/init.d/net.wlp1s0
rc-update add net.wlp1s0 default
rc-update add wpa_supplicant default
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

#echo "----- Step 6 Prepare SDCARD --"
#mkdir -p "$PROJ_DIR"/out/release_SD/gentoo
#cp -a "$TARGET_DIR"/boot/* "$PROJ_DIR"/out/release_SD/gentoo
#cd "$PROJ_DIR"/out/release_SD
#zip -r ../release_SD.zip *
