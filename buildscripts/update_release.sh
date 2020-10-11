#!/bin/sh
CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"
TARGET_DIR="$PROJ_DIR"/out/release

if ! [ "$1" == "noupdate" ]; then
	"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
emerge --usepkg --with-bdeps=n -uvDN --jobs=5 app-portage/nintendo-switch-release-meta @system @world
emerge --depclean
EOF
fi

echo '#####################################################'
echo "----- Step 4 cleanup and finalize"
echo '#####################################################'
"$PROJ_DIR"/tools/system_chroot/chroot-umount.sh "$TARGET_DIR" # Be sure all is unmounted in case of errors
umount -v "$TARGET_DIR"/var/cache/binpkgs

rm -Rf "$TARGET_DIR"/tmp/*
rm -Rf "$TARGET_DIR"/var/tmp/*
rm "$TARGET_DIR"/var/log/emerge*
rm "$TARGET_DIR"/var/log/portage/elog/summary.log
rm -Rf "$TARGET_DIR"/var/cache/edb/binhost
rm "$TARGET_DIR"/etc/resolv.conf
rm "$TARGET_DIR"/root/.bash_history

echo "----- Step 5 create tar package --"
cd "$TARGET_DIR"
rm ../switch-gentoo-root-"$(date +"%Y-%m-%d")".tar.gz
tar -czf ../switch-gentoo-root-"$(date +"%Y-%m-%d")".tar.gz *

echo "----- Step 6 Build SDCARD --"
rm -Rf "$PROJ_DIR"/out/release_SD
cp -av "$TARGET_DIR"/usr/share/sdcard1 "$PROJ_DIR"/out/release_SD/

cd "$PROJ_DIR"/out/release_SD
rm ../switch-gentoo-boot-"$(date +"%Y-%m-%d")".zip
zip -r ../switch-gentoo-boot-"$(date +"%Y-%m-%d")".zip *

echo "----- Step 7 create ext4-Image --"
EXT4_IMG="$PROJ_DIR"/out/switch-gentoo-root-"$(date +"%Y-%m-%d")".ext4
rm "$EXT4_IMG"*
truncate -s 4194300K "$EXT4_IMG"  # Size is 4G (max size) minus 4k block
mkfs.ext4 -L "switch-gentoo" "$EXT4_IMG"
mkdir "$PROJ_DIR"/out/tmpmount
modprobe loop # if not loaded
mount -v -o loop "$EXT4_IMG" "$PROJ_DIR"/out/tmpmount || exit 1
cp -a "$TARGET_DIR"/* "$PROJ_DIR"/out/tmpmount
umount -v "$PROJ_DIR"/out/tmpmount
rmdir "$PROJ_DIR"/out/tmpmount

echo "----- Step 8 Compose hekate package --"
rm -Rf "$PROJ_DIR"/out/release_HEKATE
mkdir -p "$PROJ_DIR"/out/release_HEKATE/switchroot/install
mkdir -p "$PROJ_DIR"/out/release_HEKATE/bootloader/ini

cp -a "$PROJ_DIR"/out/release_SD/switchroot/* "$PROJ_DIR"/out/release_HEKATE/switchroot
cp -a "$PROJ_DIR"/out/release_SD/bootloader/ini/* "$PROJ_DIR"/out/release_HEKATE/bootloader/ini
cp -a "$EXT4_IMG" "$PROJ_DIR"/out/release_HEKATE/switchroot/install/l4t.00

cd "$PROJ_DIR"/out/release_HEKATE
rm ../switch-gentoo-hekate-"$(date +"%Y-%m-%d")".7z
7z a ../switch-gentoo-hekate-"$(date +"%Y-%m-%d")".7z *

echo "----- Step 9 Compress ext4 image --"
gzip "$EXT4_IMG"
