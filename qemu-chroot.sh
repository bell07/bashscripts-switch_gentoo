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

"$PROJ_DIR"/tools/system_chroot/chroot-mount.sh "$TARGET_DIR"

mkdir -p "$TARGET_DIR"/usr/portage/packages
mount -v --bind "$PACKAGES" "$TARGET_DIR"/usr/portage/packages
mount -v --bind "$PROJ_DIR"/tools/switch_overlay "$TARGET_DIR"/var/db/repos/switch_overlay
mount -v --bind "$PROJ_DIR"/packages "$TARGET_DIR"/var/cache/binpkgs

echo "Entering chroot ..."
cp /usr/bin/qemu-aarch64 "$TARGET_DIR"/usr/bin/
chroot "$TARGET_DIR" $CMD
rm "$TARGET_DIR"/usr/bin/qemu-aarch64
echo "Left chroot"

"$PROJ_DIR"/tools/system_chroot/chroot-umount.sh "$TARGET_DIR"
# umount -v "$TARGET_PATH"/usr/portage/packages recursive umounted by chroot-umount.sh

umount -v "$TARGET_DIR"/var/db/repos/switch_overlay
umount -v "$TARGET_DIR"/var/cache/binpkgs
