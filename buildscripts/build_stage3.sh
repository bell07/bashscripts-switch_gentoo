#!/bin/sh
CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"

TARGET_DIR="$PROJ_DIR"/out/release_stage3

## Setup fresh build
if ! [ -d "$TARGET_DIR" ]; then
	echo '#####################################################'
	echo "----- Create new stage"
	echo '#####################################################'

	LATEST_FILE=($(curl 'http://distfiles.gentoo.org/releases/arm64/autobuilds/latest-stage3-arm64-openrc.txt' | grep -v ^#)) || exit 1

	BASE_STAGE="$(basename ${LATEST_FILE[0]})"
	BASE_STAGE_URL="http://distfiles.gentoo.org/releases/arm64/autobuilds/current-stage3-arm64-openrc/${BASE_STAGE}"
	echo "Use latest autobuild version $BASE_STAGE from $BASE_STAGE_URL"

	if ! [ -f "$PROJ_DIR"/tmp/"$BASE_STAGE" ]; then
		mkdir "$PROJ_DIR"/tmp 2>/dev/null
		wget -O "$PROJ_DIR"/tmp/"$BASE_STAGE" "$BASE_STAGE_URL"
	fi

	mkdir /scripts/switch_gentoo/out/release_stage3 || exit 1
	cd "$TARGET_DIR"  || exit 1
	tar -xf "$PROJ_DIR"/tmp/"$BASE_STAGE" || exit 1

	# Enable new layout
	mkdir -p "$TARGET_DIR"/etc/portage/repos.conf/
	mkdir -p "$TARGET_DIR"/var/db/repos/gentoo/

	cat > "$TARGET_DIR"/etc/portage/repos.conf/switch_overlay.conf << EOF
[switch]
location = /var/db/repos/switch_overlay
sync-type = git
sync-uri = https://gitlab.com/bell07/gentoo-switch_overlay
auto-sync = yes
EOF

	# Do initial setup
	"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
# Delete catalyst settings - Migrate to new portage locations
rm /etc/portage/make.conf
rm /etc/portage/make.profile
eselect profile set default/linux/arm64/17.0

# Update toolchain at the first if anything needs to be compiled
emerge --usepkg --with-bdeps=n -1uj sys-devel/binutils sys-devel/gcc sys-kernel/linux-headers sys-libs/glibc

# Remove old versions
emerge --depclean sys-devel/binutils sys-devel/gcc sys-kernel/linux-headers sys-libs/glibc
. /etc/profile

# Full rebuild system
emerge --usepkg --with-bdeps=n -evDN --jobs=5 --keep-going system
emerge --usepkg --with-bdeps=n --jobs=5 dev-vcs/git
emerge --depclean --with-bdeps=n
EOF
else
	echo '#####################################################'
	echo "----- Update stage"
	echo '#####################################################'
	# Just do update
	"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
emerge --usepkg --with-bdeps=n --changed-deps y --jobs=5 --keep-going -uvDN world
emerge --depclean --with-bdeps=n
EOF
fi

echo '#####################################################'
echo "-----Cleanup"
echo '#####################################################'
"$PROJ_DIR"/tools/system_chroot/chroot-umount.sh "$TARGET_DIR" # Be sure all is unmounted in case of errors
umount -v "$TARGET_DIR"/var/cache/binpkgs
rm "$TARGET_DIR"/etc/resolv.conf
rm -Rf "$TARGET_DIR"/var/cache/edb/binhost
rm "$TARGET_DIR"/var/log/emerge*
rm "$TARGET_DIR"/var/log/portage/elog/summary.log
rm "$TARGET_DIR"/root/.bash_history
rm -Rf "$TARGET_DIR"/var/tmp/*
rmdir "$TARGET_DIR"/var/db/repos/switch_binhost_overlay/

echo '#####################################################'
echo "----- create tar package --"
echo '#####################################################'
cd "$TARGET_DIR"
rm "$PROJ_DIR"/out/pub/switch-gentoo-stage3-"$(date +"%Y-%m-%d")".tar.xz
tar -cJf "$PROJ_DIR"/out/pub/switch-gentoo-stage3-"$(date +"%Y-%m-%d")".tar.xz *
