#!/bin/sh
CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"

BASE_STAGE=stage3-arm64-20190613.tar.bz2
BASE_STAGE_URL=http://distfiles.gentoo.org/experimental/arm64/"${BASE_STAGE}"

TARGET_DIR="$PROJ_DIR"/out/release

if [ -n "$(mount | grep "$TARGET_DIR")" ]; then
	echo Something mounted
	exit 1
fi

echo '#####################################################'
echo "----- Step 1 Delete and unpack new stage"
echo '#####################################################'

rm -Rf "$TARGET_DIR"
mkdir "$TARGET_DIR"  || exit 1
cd "$TARGET_DIR"  || exit 1

if ! [ -f "$PROJ_DIR"/tmp/"$BASE_STAGE" ]; then
	mkdir "$PROJ_DIR"/tmp
	wget -O "$PROJ_DIR"/tmp/"$BASE_STAGE" "$BASE_STAGE_URL"
fi

tar -jxf "$PROJ_DIR"/tmp/"$BASE_STAGE" || exit 1

echo '#####################################################' 
echo "----- Step 2. Install world"
echo '#####################################################'
mkdir -p "$TARGET_DIR"/usr/portage
mount -v --bind /usr/portage "$TARGET_DIR"/usr/portage
mkdir -p "$TARGET_DIR"/var/db/repos/switch_binhost_overlay


RELEASE_SETUP="$(cat "$CFG_DIR"/do_release_setup.sh)"


"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF

PORTDIR_OVERLAY=/var/db/repos/switch_binhost_overlay FEATURES="-pid-sandbox" emerge -v app-portage/nintendo-switch-overlay
eselect profile set switch_binhost:nintendo_switch_binhost/17.0_desktop

#FEATURES="-pid-sandbox buildpkg" emerge --usepkg --with-bdeps=n -evDN --jobs=5 app-portage/nintendo-switch-release-meta @system @world
FEATURES="-pid-sandbox buildpkg" emerge --depclean

echo '#####################################################'
echo '----- Step 3. Configure'
echo '#####################################################'
$RELEASE_SETUP
EOF

echo '#####################################################'
echo "----- Step 4 cleanup and finalize"
echo '#####################################################'
"$PROJ_DIR"/tools/system_chroot/chroot-umount.sh "$TARGET_DIR" # Be sure all is unmounted in case of errors
umount -v "$TARGET_DIR"/var/cache/binpkgs

rm -Rf "$TARGET_DIR"/var/tmp/portage
rm "$TARGET_DIR"/var/log/emerge.log
rm "$TARGET_DIR"/var/log/emerge-fetch.log
rm "$TARGET_DIR"/var/log/portage/elog/summary.log
rm -Rf "$TARGET_DIR"/var/cache/edb/binhost
rm "$TARGET_DIR"/etc/resolv.conf

echo "----- Step 5 create package --"
cd "$TARGET_DIR"
tar -czf ../switch-gentoo-release-"$(date +"%Y-%m-%d")".tar.gz *

echo "----- Step 6 Build SDCARD --"
rm -Rf "$PROJ_DIR"/out/release_SD
mkdir -p "$PROJ_DIR"/out/release_SD/gentoo
cp -a "$TARGET_DIR"/boot/* "$PROJ_DIR"/out/release_SD/gentoo
mkdir -p "$PROJ_DIR"/out/release_SD/bootloader/ini
echo "[Gentoo $(date +"%Y-%m-%d") by bell07]" > "$PROJ_DIR"/out/release_SD/bootloader/ini/Gentoo.ini
echo "payload=gentoo/coreboot.rom" >> "$PROJ_DIR"/out/release_SD/bootloader/ini/Gentoo.ini

cd "$PROJ_DIR"/out/release_SD
zip -r ../switch-gentoo-boot-"$(date +"%Y-%m-%d")".zip *
