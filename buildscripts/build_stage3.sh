#!/bin/sh
CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"

TARGET_DIR="$PROJ_DIR"/out/release_stage3
STAGE_CONFIGROOT="$PROJ_DIR"/stage3-build/portage_configroot

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

## Setup fresh build
if ! [ -d "$TARGET_DIR" ]; then
	echo '#####################################################'
	echo "----- Create new stage"
	echo '#####################################################'

	"$CFG_DIR"/do_skeleton.sh "$TARGET_DIR" portage

	mount -o bind /var/cache/distfiles "$TARGET_DIR"/var/cache/distfiles
	mount -o bind /var/db/repos/gentoo "$TARGET_DIR"/var/db/repos/gentoo
	mount -o bind "$PROJ_DIR"/packages "$TARGET_DIR"/var/cache/binpkgs
	mount -o bind "$PROJ_DIR"/overlays/switch_overlay "$TARGET_DIR"/var/db/repos/switch_overlay

	# Build essential toolchain packages
	ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$STAGE_CONFIGROOT" \
			aarch64-unknown-linux-gnu-emerge -uv1 --jobs=5 --buildpkg n sys-devel/gcc glibc binutils linux-headers

	# Build @system
	ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$STAGE_CONFIGROOT" \
			aarch64-unknown-linux-gnu-emerge -uv1 --jobs=5 --buildpkg n --with-bdeps y @system

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
# Remove old versions
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
env-update
. /etc/profile

# Full rebuild system
eselect profile set bell07:my_switch_stage
FEATURES="$FEATURES -distcc" emerge --with-bdeps=n -evDN --jobs=5 --keep-going system
FEATURES="$FEATURES -distcc" emerge --with-bdeps=n -v --jobs=5 --usepkg dev-vcs/git
emerge --depclean --with-bdeps=n
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
FEATURES="$FEATURES -distcc" emerge --usepkg --with-bdeps=n --changed-deps y --jobs=5 --keep-going -uvDN world
FEATURES="$FEATURES -distcc" emerge --depclean --with-bdeps=n
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
tar -cJf "$PROJ_DIR"/out/pub/switch-gentoo-stage3-"$(date +"%Y-%m-%d")".tar.xz *
