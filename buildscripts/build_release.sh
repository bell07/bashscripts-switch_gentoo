#!/bin/sh
CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"

BASE_STAGE=stage3-arm64-20190613.tar.bz2
BASE_STAGE_URL=http://distfiles.gentoo.org/experimental/arm64/"${BASE_STAGE}"

TARGET_DIR="$PROJ_DIR"/out/release

if [ -n "$(mount | grep "$TARGET_DIR")" ]; then
	echo Something mounted
	exit 1
fi

echo '#####################################################'
echo "----- Step 1 Delete and unpack new stage"
echo '#####################################################'

rm -Rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"  || exit 1
cd "$TARGET_DIR"  || exit 1

if ! [ -f "$PROJ_DIR"/tmp/"$BASE_STAGE" ]; then
	mkdir "$PROJ_DIR"/tmp
	wget -O "$PROJ_DIR"/tmp/"$BASE_STAGE" "$BASE_STAGE_URL"
fi

tar -jxf "$PROJ_DIR"/tmp/"$BASE_STAGE" || exit 1

echo '#####################################################'
echo "----- Step 2. Install world"
echo '#####################################################'
mkdir -p "$TARGET_DIR"/usr/portage
mount -v --bind /usr/portage "$TARGET_DIR"/usr/portage
mkdir -p "$TARGET_DIR"/var/db/repos/switch_binhost_overlay


RELEASE_SETUP="$(cat "$CFG_DIR"/do_release_setup.sh)"


"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF

PORTDIR_OVERLAY="/var/db/repos/switch_binhost_overlay" \
	FEATURES="getbinpkg -pid-sandbox" PORTAGE_BINHOST="http://bell.7u.org/pub/gentoo-switch/packages/" \
	emerge -vj --nodeps app-portage/nintendo-switch-overlay

eselect profile set switch_binhost:nintendo_switch_binhost/17.0_desktop_base
mv /etc/portage/make.conf /etc/portage/make.conf.orig

emerge --usepkg --with-bdeps=n -1uj sys-devel/binutils sys-devel/gcc:9.2.0 sys-kernel/linux-headers sys-libs/glibc
emerge --depclean sys-devel/binutils sys-devel/gcc sys-kernel/linux-headers sys-libs/glibc
. /etc/profile

emerge --buildpkg --usepkg --with-bdeps=n -evDN --jobs=5 app-portage/nintendo-switch-release-meta @system @world
emerge --depclean

echo '#####################################################'
echo '----- Step 3. Configure'
echo '#####################################################'
$RELEASE_SETUP
EOF

"$CFG_DIR"/update_release.sh noupdate
