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

echo "----- Step 5 create package --"
cd "$TARGET_DIR"
rm ../switch-gentoo-release-"$(date +"%Y-%m-%d")".tar.gz
tar -czf ../switch-gentoo-release-"$(date +"%Y-%m-%d")".tar.gz *

echo "----- Step 6 Build SDCARD --"
rm -Rf "$PROJ_DIR"/out/release_SD
cp -av "$TARGET_DIR"/usr/share/sdcard1 "$PROJ_DIR"/out/release_SD/
cp -av "$TARGET_DIR"/boot "$PROJ_DIR"/out/release_SD/gentoo

cd "$PROJ_DIR"/out/release_SD
rm ../switch-gentoo-boot-"$(date +"%Y-%m-%d")".zip
zip -r ../switch-gentoo-boot-"$(date +"%Y-%m-%d")".zip *
