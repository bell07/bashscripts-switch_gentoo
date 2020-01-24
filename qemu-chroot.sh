#!/bin/bash
PROJ_DIR="$(dirname $0)"

if [ -n "$1" ]; then
	TARGET_DIR="$1"
	shift
	if [ -n "$1" ]; then
		CMD="${*}"
	else
		CMD="/bin/bash --login"
	fi
else
	TARGET_DIR="$PROJ_DIR"/root
fi

PACKAGES="$PROJ_DIR"/packages

/etc/init.d/qemu-binfmt start
/etc/init.d/distccd start
gcc-config aarch64-unknown-linux-gnu-9.2.0

"$PROJ_DIR"/tools/system_chroot/chroot-mount.sh "$TARGET_DIR"

mkdir -p "$TARGET_DIR"/usr/portage/packages
mount -v --bind "$PACKAGES" "$TARGET_DIR"/usr/portage/packages
mount -v --bind "$PROJ_DIR"/overlays "$TARGET_DIR"/var/db/repos
mkdir -p "$PACKAGES"
mount -v --bind "$PACKAGES" "$TARGET_DIR"/var/cache/binpkgs

echo 'export FEATURES="-pid-sandbox"'
export FEATURES="-pid-sandbox"

echo "Entering chroot ..."
cp /usr/bin/qemu-aarch64 "$TARGET_DIR"/usr/bin/
echo chroot "$TARGET_DIR" $CMD
chroot "$TARGET_DIR" $CMD
rm "$TARGET_DIR"/usr/bin/qemu-aarch64
echo "Left chroot"

"$PROJ_DIR"/tools/system_chroot/chroot-umount.sh "$TARGET_DIR"
# umount -v "$TARGET_PATH"/usr/portage/packages recursive umounted by chroot-umount.sh

umount -v "$TARGET_DIR"/var/db/repos
umount -v "$TARGET_DIR"/usr/portage/packages
umount -v "$TARGET_DIR"/var/cache/binpkgs
