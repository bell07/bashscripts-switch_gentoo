#!/bin/bash

if [ -n "$1" ]; then
	TARGET_DIR="$1"
	shift
	if [ -n "$1" ]; then
		CMD="${*}"
	else
		CMD="/bin/bash --login"
	fi
else
	TARGET_DIR=root
fi

PACKAGES=packages

/etc/init.d/qemu-binfmt start
/etc/init.d/distccd start

tools/system_chroot/chroot-mount.sh "$TARGET_DIR"

mount -v --bind "$PACKAGES" "$TARGET_DIR"/usr/portage/packages
mount -v --bind tools/switch_overlay "$TARGET_DIR"/var/db/repos/switch_overlay/

echo "Entering chroot ..."
cp /usr/bin/qemu-aarch64 "$TARGET_DIR"/usr/bin/
chroot "$TARGET_DIR" $CMD
rm "$TARGET_DIR"/usr/bin/qemu-aarch64
echo "Left chroot"

tools/system_chroot/chroot-umount.sh "$TARGET_DIR"
# umount -v "$TARGET_PATH"/usr/portage/packages recursive umounted by chroot-umount.sh

umount -v "$TARGET_DIR"/var/db/repos/switch_overlay/
