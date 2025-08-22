#!/bin/sh
CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"

TARGET_DIR="$PROJ_DIR"/out/release_stage3
STAGE_CONFIGROOT="$PROJ_DIR"/stage3-build/portage_configroot
JOBS=20


function setup_bell07_overlay() {
	mkdir "$TARGET_DIR"/var/db/repos/bell07
	cat > "$TARGET_DIR"/etc/portage/repos.conf/bell07_overlay.conf << EOF
[bell07]
location = /var/db/repos/bell07
EOF
}

function remove_bell07_overlay() {
 rm "$TARGET_DIR"/etc/portage/repos.conf/bell07_overlay.conf
 umount -q "$TARGET_DIR"/var/db/repos/bell07
 rmdir "$TARGET_DIR"/var/db/repos/bell07
}

function cross_emerge() {
	echo ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$STAGE_CONFIGROOT" \
		"$PROJ_DIR"/nsw-cross-distcc-docker/cross-emerge.sh --verbose \
		--binpkg-changed-deps n --with-bdeps=n --jobs=$JOBS --buildpkg n $@

	ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$STAGE_CONFIGROOT" \
		"$PROJ_DIR"/nsw-cross-distcc-docker/cross-emerge.sh --verbose \
		--binpkg-changed-deps n --with-bdeps=n --jobs=$JOBS --buildpkg n $@
}

NATIVE_EMERGE='FEATURES="-distcc" emerge --with-bdeps=y --changed-deps=y --jobs='$JOBS' --keep-going'


## Setup fresh build
if ! [ -d "$TARGET_DIR" ]; then
	echo '#####################################################'
	echo "----- Create new stage"
	echo '#####################################################'

	"$CFG_DIR"/do_skeleton.sh "$TARGET_DIR" portage

	# Build essential toolchain packages
	echo "# install baselayout"
	cross_emerge -1 sys-apps/baselayout

	echo "# install toolchain"
	cross_emerge -1 sys-devel/gcc \
		sys-libs/glibc
		sys-devel/binutils
		sys-kernel/linux-headers

	echo "# install system with some build deps"
	cross_emerge -1 @system \
		app-admin/eselect \
		sys-apps/locale-gen \
		dev-build/autoconf

	cat > "$TARGET_DIR"/etc/portage/repos.conf/switch_overlay.conf << EOF
[switch]
location = /var/db/repos/switch_overlay
sync-type = git
sync-uri = https://gitlab.com/bell07/gentoo-switch_overlay
auto-sync = yes
EOF

	# Do initial setup
	setup_bell07_overlay

	"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
eselect profile set bell07:my_switch_stage

/usr/bin/env-update
. /etc/profile
# Remove old versions
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen

# Full rebuild world
$NATIVE_EMERGE --binpkg-changed-deps y -evDN @world dev-vcs/git
$NATIVE_EMERGE --depclean

eselect profile set switch:nintendo_switch/17.0
EOF
else
	echo '#####################################################'
	echo "----- Update stage"
	echo '#####################################################'
	# Just do update
	setup_bell07_overlay
	"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
eselect profile set bell07:my_switch_stage

$NATIVE_EMERGE -uvDN @world
$NATIVE_EMERGE --binpkg-changed-deps y -uvDN @changed-deps @changed-subslot @world
$NATIVE_EMERGE --depclean

eselect profile set switch:nintendo_switch/17.0
EOF
fi


"$CFG_DIR"/do_clearup.sh "$TARGET_DIR"
remove_bell07_overlay

echo '#####################################################'
echo "----- create tar package --"
echo '#####################################################'
cd "$TARGET_DIR"
rm "$PROJ_DIR"/out/pub/switch-gentoo-stage3-"$(date +"%Y-%m-%d")".tar.xz
XZ_OPT='-T0 -9' tar -cJf "$PROJ_DIR"/out/pub/switch-gentoo-stage3-"$(date +"%Y-%m-%d")".tar.xz *
