#!/bin/sh
TARGET_DIR=out/stage3
mkdir -p "$TARGET_DIR"

echo " ----- Step 1. Build base files"
cp -av target-cfg/00_base/* "$TARGET_DIR"
cp -av target-cfg/02_stage/* "$TARGET_DIR"

mkdir -p "$TARGET_DIR"/usr/portage
mount -v --bind /usr/portage "$TARGET_DIR"/usr/portage
ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$TARGET_DIR" USE=build emerge -v1q --buildpkg=n --usepkg=n baselayout

echo " ----- Step 2. Install system"
ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$TARGET_DIR" PKGDIR="packages" emerge --usepkgonly -evDN --jobs=2 @system

echo " ----- Step 3. Install build dependencies"
mkdir -p "$TARGET_DIR"/var/cache/binpkgs
mount -v --bind packages "$TARGET_DIR"/var/cache/binpkgs

./qemu-chroot.sh "$TARGET_DIR"  << EOF
env-update
source /etc/profile
FEATURES="-pid-sandbox buildpkg" emerge --usepkg --with-bdeps=y -uvDN --jobs=2 @system
EOF

umount -v "$TARGET_DIR"/var/cache/binpkgs

echo " ----- Step 4 cleanup and finalize"
rm -Rf "$TARGET_DIR"/var/tmp/portage
rm "$TARGET_DIR"/var/log/emerge.log
rm "$TARGET_DIR"/var/log/emerge-fetch.log
rm "$TARGET_DIR"/var/log/portage/elog/summary.log
rm -Rf "$TARGET_DIR"/var/cache/edb/binhost
rm -Rf "$TARGET_DIR"/var/cache/binpkgs
rm "$TARGET_DIR"/etc/resolv.conf


echo "Patch make.conf to use bell's binhost"
cat >> "$TARGET_DIR"/etc/portage/make.conf <<EOL

PORTAGE_BINHOST="http://bell.7u.org/pub/gentoo-switch/packages/"
FEATURES="\$FEATURES getbinpkg"
EOL

echo "----- Step 5 create stage package --"
cd "$TARGET_DIR"
tar -czf ../switch-gentoo-stage3.tar.gz *
