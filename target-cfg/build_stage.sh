#!/bin/sh
CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"

TARGET_DIR="$PROJ_DIR"/out/stage3

echo " ----- Step 1. Build base files"
mkdir -p "$TARGET_DIR"/usr/portage
mount -v --bind /usr/portage "$TARGET_DIR"/usr/portage
# install overlay
ROOT="$TARGET_DIR" PORTDIR_OVERLAY="$PROJ_DIR"/tools/switch_overlay ACCEPT_KEYWORDS='**' \
		USE=build emerge -vq --buildpkg=n --usepkg=n --nodeps app-portage/nintendo-switch-overlay

# set to overlay profile
mkdir -p "$TARGET_DIR"/etc/portage/
ln -s "$PROJ_DIR"/tools/switch_overlay/profiles/nintendo_switch/17.0/binary "$TARGET_DIR"/etc/portage/make.profile

# install baselayout
ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$TARGET_DIR" PORTDIR_OVERLAY="$PROJ_DIR"/tools/switch_overlay FEATURES="-getbinpkg" \
		USE=build emerge -v1q --buildpkg=n --usepkg=n baselayout

echo " ----- Step 2. Install system for working portage"
echo "... warinig about missed overlay is ok at this point"
ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$TARGET_DIR" PKGDIR="$PROJ_DIR"/packages FEATURES="-getbinpkg" \
		emerge -1v --usepkgonly --with-bdeps=n --jobs=5 $(cat /usr/portage/profiles/base/packages | grep '^*' | sed 's/^*//g')

echo " ----- Step 3. Re-Install system in chroot"
mkdir -p "$TARGET_DIR"/var/cache/binpkgs

"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
env-update
source /etc/profile
eselect profile set switch:nintendo_switch/17.0/binary
FEATURES="-pid-sandbox buildpkg" emerge --usepkg --with-bdeps=y -evDN --jobs=5 @system @world
EOF

"$PROJ_DIR"/tools/system_chroot/chroot-umount.sh "$TARGET_DIR" # Be sure all is unmounted in case of errors

echo " ----- Step 4 cleanup and finalize"
rm -Rf "$TARGET_DIR"/var/tmp/portage
rm "$TARGET_DIR"/var/log/emerge.log
rm "$TARGET_DIR"/var/log/emerge-fetch.log
rm "$TARGET_DIR"/var/log/portage/elog/summary.log
rm -Rf "$TARGET_DIR"/var/cache/edb/binhost
rm "$TARGET_DIR"/etc/resolv.conf

echo "----- Step 5 create stage package --"
cd "$TARGET_DIR"
tar -czf ../switch-gentoo-stage3.tar.gz *
