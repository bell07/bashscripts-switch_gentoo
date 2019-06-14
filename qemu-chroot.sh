#!/bin/bash

TARGET=aarch64-unknown-linux-gnu
TARGET_PATH=./root
PACKAGES=./packages

/etc/init.d/qemu-binfmt start

tools/system_chroot/chroot-mount.sh "$TARGET_PATH"

mount --bind "$PACKAGES" ${TARGET_PATH}/usr/portage/packages

echo "Entering chroot ..."
cp /usr/bin/qemu-aarch64 ${TARGET_PATH}/usr/bin/
chroot ${TARGET_PATH} /bin/bash --login
rm ${TARGET_PATH}/usr/bin/qemu-aarch64
echo "Left chroot"

tools/system_chroot/chroot-umount.sh root/
