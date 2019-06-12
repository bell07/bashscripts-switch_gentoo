#!/bin/sh
TARGET_DIR=out/stage4
mkdir -p "$TARGET_DIR"

echo "-- mount build environment  --"
../system-chroot/chroot-mount.sh root/


echo "-- build baselayout --"
ARCH=arm64 ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT=root/ USE=build emerge -v1j baselayout

echo "-- build system --"
ARCH=arm64 ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT=root/ PKGDIR=packages/ emerge --usepkg -evj @system

echo "-- umount build environment  --"
../system-chroot/chroot-umount.sh root/

echo "-- copy target files --"
cp -av target/* "$TARGET_DIR"

echo "-- create stage package --"
cd "$TARGET_DIR"
tar -czvf ../switch-gentoo-stage4.tar.gz *
