#!/bin/sh
CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"
TARGET_DIR="$PROJ_DIR"/out/release

[[ -d "$PROJ_DIR"/out/pub ]] || mkdir -p "$PROJ_DIR"/out/pub

if ! [ "$1" == "noupdate" ]; then
	function create_world() {
		source "$PROJ_DIR"/overlays/switch_binhost_overlay/app-portage/nintendo-switch-release-meta/nintendo-switch-release-meta-0.2.ebuild
		rm "$TARGET_DIR"/var/lib/portage/world
		for package in $RDEPEND; do
			echo "$package" >> "$TARGET_DIR"/var/lib/portage/world
		done
	}
	create_world

	"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
eselect profile set switch_binhost:nintendo_switch_binhost/17.0_desktop
emerge --usepkg --with-bdeps=n -uvDN --jobs=5 @system @world
emerge --depclean --with-bdeps=n
eselect profile set switch:nintendo_switch/17.0/desktop
EOF
fi

echo '#####################################################'
echo "----- Step 4 cleanup and finalize"
echo '#####################################################'
"$PROJ_DIR"/tools/system_chroot/chroot-umount.sh "$TARGET_DIR" # Be sure all is unmounted in case of errors
umount -v "$TARGET_DIR"/var/cache/binpkgs

rm "$TARGET_DIR"/boot/*.old
rm "$TARGET_DIR"/etc/resolv.conf
rm -Rf "$TARGET_DIR"/root/*
rm -Rf "$TARGET_DIR"/root/.*
touch "$TARGET_DIR"/root/.keep
rm -Rf "$TARGET_DIR"/tmp/*
rm -Rf "$TARGET_DIR"/var/cache/edb/binhost
rm "$TARGET_DIR"/var/log/emerge*
rm "$TARGET_DIR"/var/log/portage/elog/summary.log
rm "$TARGET_DIR"/root/.bash_history
rm -Rf "$TARGET_DIR"/var/tmp/*


export XZ_OPT="-ve -T0" # speed up the xz compressions

echo '#####################################################'
echo "----- Step 5 create tar package --"
echo '#####################################################'
cd "$TARGET_DIR"
rm "$PROJ_DIR"/out/pub/switch-gentoo-root-"$(date +"%Y-%m-%d")".tar.xz
tar -cJf "$PROJ_DIR"/out/pub/switch-gentoo-root-"$(date +"%Y-%m-%d")".tar.xz *

echo '#####################################################'
echo "----- Step 6 Build SDCARD --"
echo '#####################################################'
rm -Rf "$PROJ_DIR"/out/release_SD
cp -av "$TARGET_DIR"/usr/share/sdcard1 "$PROJ_DIR"/out/release_SD/

cd "$PROJ_DIR"/out/release_SD
rm "$PROJ_DIR"/out/pub/switch-gentoo-boot-"$(date +"%Y-%m-%d")".zip
zip -r "$PROJ_DIR"/out/pub/switch-gentoo-boot-nyx-"$(date +"%Y-%m-%d")".zip *
zip -r "$PROJ_DIR"/out/pub/switch-gentoo-boot-"$(date +"%Y-%m-%d")".zip switchroot bootloader/ini

echo '#####################################################'
echo "----- Step 7 create ext4-Image --"
echo '#####################################################'
EXT4_IMG="$PROJ_DIR"/out/pub/switch-gentoo-root-"$(date +"%Y-%m-%d")".ext4
rm "$EXT4_IMG"*
truncate -s 4194300K "$EXT4_IMG"  # Size is 4G (max size) minus 4k block
mkfs.ext4 -L "switch-gentoo" "$EXT4_IMG"
[[ -d "$PROJ_DIR"/out/tmpmount ]] || mkdir "$PROJ_DIR"/out/tmpmount
modprobe loop # if not loaded
mount -v -o loop "$EXT4_IMG" "$PROJ_DIR"/out/tmpmount || exit 1
cp -a "$TARGET_DIR"/* "$PROJ_DIR"/out/tmpmount
umount -v "$PROJ_DIR"/out/tmpmount
rmdir "$PROJ_DIR"/out/tmpmount

echo '#####################################################'
echo "----- Step 8 Compose hekate package --"
echo '#####################################################'
rm -Rf "$PROJ_DIR"/out/release_HEKATE
mkdir -p "$PROJ_DIR"/out/release_HEKATE/switchroot/install
mkdir -p "$PROJ_DIR"/out/release_HEKATE/bootloader/ini

cp -a "$PROJ_DIR"/out/release_SD/switchroot/* "$PROJ_DIR"/out/release_HEKATE/switchroot
cp -a "$PROJ_DIR"/out/release_SD/bootloader/ini/* "$PROJ_DIR"/out/release_HEKATE/bootloader/ini
cp -a "$EXT4_IMG" "$PROJ_DIR"/out/release_HEKATE/switchroot/install/l4t.00

cd "$PROJ_DIR"/out/release_HEKATE
rm "$PROJ_DIR"/out/pub/switch-gentoo-hekate-"$(date +"%Y-%m-%d")".7z
7z a "$PROJ_DIR"/out/pub/switch-gentoo-hekate-"$(date +"%Y-%m-%d")".7z *

echo '#####################################################'
echo "----- Step 9 Compress ext4 image --"
echo '#####################################################'
xz "$EXT4_IMG"
