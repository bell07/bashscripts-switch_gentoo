#!/bin/bash

TARGET=aarch64-unknown-linux-gnu
TARGET_DIR=./root
PACKAGES=./packages

/etc/init.d/qemu-binfmt start

tools/system_chroot/chroot-mount.sh "$TARGET_DIR"

mount -v --bind "$PACKAGES" "$TARGET_DIR"/usr/portage/packages

echo "Entering chroot ..."
cp /usr/bin/qemu-aarch64 "$TARGET_DIR"/usr/bin/
chroot "$TARGET_DIR" /bin/bash --login
rm "$TARGET_DIR"/usr/bin/qemu-aarch64
echo "Left chroot"

tools/system_chroot/chroot-umount.sh root/
# umount -v "$TARGET_PATH"/usr/portage/packages recursive umounted by chroot-umount.sh
