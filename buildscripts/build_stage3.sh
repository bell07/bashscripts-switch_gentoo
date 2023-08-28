#!/bin/sh
CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"

TARGET_DIR="$PROJ_DIR"/out/release_stage3

## Setup fresh build
if ! [ -d "$TARGET_DIR" ]; then
	echo '#####################################################'
	echo "----- Create new stage"
	echo '#####################################################'

	"$CFG_DIR"/do_skeleton.sh "$TARGET_DIR" portage

	cat > "$TARGET_DIR"/etc/portage/repos.conf/switch_overlay.conf << EOF
[switch]
location = $PROJ_DIR/overlays/switch_overlay
EOF

# Set switch_overlay:nintendo_switch/17.0/ profile that contain all needed setup
	ln -s "$PROJ_DIR"/overlays/switch_overlay/profiles/nintendo_switch/17.0/ "$TARGET_DIR"/etc/portage/make.profile

	mount -o bind /var/cache/distfiles "$TARGET_DIR"/var/cache/distfiles
	mount -o bind /var/db/repos/gentoo "$TARGET_DIR"/var/db/repos/gentoo
	mount -o bind "$PROJ_DIR"/packages "$TARGET_DIR"/var/cache/binpkgs
	mount -o bind "$PROJ_DIR"/overlays/switch_overlay "$TARGET_DIR"/var/db/repos/switch_overlay

	# Build essential toolchain packages
	PORTAGE_BINHOST="http://bell.7u.org/pub/gentoo-switch/packages/" FEATURES="getbinpkg" \
		ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$TARGET_DIR" \
		CHOST=aarch64-unknown-linux-gnu \
			cross-emerge -uva1 --usepkg sys-devel/gcc glibc binutils linux-headers

	# Build @system
	PORTAGE_BINHOST="http://bell.7u.org/pub/gentoo-switch/packages/" FEATURES="getbinpkg" \
		ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$TARGET_DIR" \
		CHOST=aarch64-unknown-linux-gnu \
			cross-emerge -uva1 --usepkg --with-bdeps y @system

	# Set switch_overlay:nintendo_switch/17.0/ profile that contain all needed setup
	rm "$TARGET_DIR"/etc/portage/make.profile
	ln -s ../../var/db/repos/switch_overlay/profiles/nintendo_switch/17.0/ "$TARGET_DIR"/etc/portage/make.profile

	cat > "$TARGET_DIR"/etc/portage/repos.conf/switch_overlay.conf << EOF
[switch]
location = /var/db/repos/switch_overlay
sync-type = git
sync-uri = https://gitlab.com/bell07/gentoo-switch_overlay
auto-sync = yes
EOF

	# Do initial setup
	"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
# Remove old versions
env-update
. /etc/profile

export PORTAGE_BINHOST="http://bell.7u.org/pub/gentoo-switch/packages/"
FEATURES="-pid-sandbox getbinpkg"

# Full rebuild system
emerge --with-bdeps=n -evDN --jobs=5 --keep-going --usepkg system
emerge --with-bdeps=n -v --jobs=5 --usepkg dev-vcs/git
emerge --depclean --with-bdeps=n
EOF
else
	echo '#####################################################'
	echo "----- Update stage"
	echo '#####################################################'
	# Just do update
	"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
emerge --usepkg --with-bdeps=n --changed-deps y --jobs=5 --keep-going -uvDN world
emerge --depclean --with-bdeps=n
EOF
fi

"$CFG_DIR"/do_clearup.sh "$TARGET_DIR"

echo '#####################################################'
echo "----- create tar package --"
echo '#####################################################'
cd "$TARGET_DIR"
rm "$PROJ_DIR"/out/pub/switch-gentoo-stage3-"$(date +"%Y-%m-%d")".tar.xz
tar -cJf "$PROJ_DIR"/out/pub/switch-gentoo-stage3-"$(date +"%Y-%m-%d")".tar.xz *
