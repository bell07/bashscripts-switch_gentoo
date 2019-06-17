#!/bin/sh
TARGET_DIR=out/stage4
mkdir -p "$TARGET_DIR"

cp -av target-cfg/00_base/* "$TARGET_DIR"
cp -av target-cfg/02_stage/* "$TARGET_DIR"

echo "Mount portage"
mkdir -p "$TARGET_DIR"/usr/portage
mount -v --bind /usr/portage "$TARGET_DIR"/usr/portage

echo "-- build baselayout --"
ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$TARGET_DIR" USE=build emerge -v1j baselayout
echo "-- build system --"
ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$TARGET_DIR" PKGDIR="packages" emerge --usepkg -vj @system

echo "Configure make.conf to use binhost"
cat >> "$TARGET_DIR"/etc/portage/make.conf <<EOL

PORTAGE_BINHOST="http://bell.7u.org/pub/gentoo-switch/packages/"
FEATURES="$FEATURES getbinpkg"
EOL

echo "umount portage"
umount "$TARGET_DIR"/usr/portage

echo "-- create stage package --"
cd "$TARGET_DIR"
tar -czf ../switch-gentoo-stage4.tar.gz *
