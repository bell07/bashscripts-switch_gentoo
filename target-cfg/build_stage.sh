#!/bin/sh
CFG_DIR="$(dirname $0)"
PROJ_DIR="$(dirname "$CFG_DIR")"

TARGET_DIR="$PROJ_DIR"/out/stage3

mkdir -p "$TARGET_DIR"

echo " ----- Step 1. Build base files"
cp -av "$CFG_DIR"/base/* "$TARGET_DIR"

mkdir -p "$TARGET_DIR"/usr/portage
mount -v --bind /usr/portage "$TARGET_DIR"/usr/portage
echo "Hint: warning about missed overlay is ok at this place. It is a PORTAGE_CONFIGROOT issue"
ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$TARGET_DIR" USE=build emerge -v1q --buildpkg=n --usepkg=n baselayout

echo " ----- Step 2. Install system"
ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$TARGET_DIR" PKGDIR="packages" emerge -evDN --usepkgonly --with-bdeps=n --jobs=4 @system

echo " ----- Step 3. Install build dependencies"
mkdir -p "$TARGET_DIR"/var/cache/binpkgs
mount -v --bind "$PROJ_DIR"/packages "$TARGET_DIR"/var/cache/binpkgs

"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
env-update
source /etc/profile
FEATURES="-pid-sandbox buildpkg" emerge --usepkg --with-bdeps=y -uvDN --jobs=2 @system
EOF

"$PROJ_DIR"/tools/system_chroot/chroot-umount.sh "$TARGET_DIR" # Be sure all is unmounted in case of errors

umount -v "$TARGET_DIR"/var/cache/binpkgs

echo " ----- Step 4 cleanup and finalize"
rm -Rf "$TARGET_DIR"/var/tmp/portage
rm "$TARGET_DIR"/var/log/emerge.log
rm "$TARGET_DIR"/var/log/emerge-fetch.log
rm "$TARGET_DIR"/var/log/portage/elog/summary.log
rm -Rf "$TARGET_DIR"/var/cache/edb/binhost
rm "$TARGET_DIR"/etc/resolv.conf


echo "Patch make.conf to use bell's binhost"
cat >> "$TARGET_DIR"/etc/portage/make.conf <<EOL

PORTAGE_BINHOST="http://bell.7u.org/pub/gentoo-switch/packages/"
FEATURES="\$FEATURES getbinpkg"
EOL

echo "----- Step 5 create stage package --"
cd "$TARGET_DIR"
tar -czf ../switch-gentoo-stage3.tar.gz *
