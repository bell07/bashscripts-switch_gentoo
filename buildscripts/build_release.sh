#!/bin/sh
CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"

LATEST_FILE=($(curl 'http://distfiles.gentoo.org/releases/arm64/autobuilds/latest-stage3-arm64.txt' | grep -v ^#)) || exit 1

BASE_STAGE="$(basename ${LATEST_FILE[0]})"
BASE_STAGE_URL="http://distfiles.gentoo.org/releases/arm64/autobuilds/current-stage3-arm64/${BASE_STAGE}"
echo "Use latest autobuild version $BASE_STAGE from $BASE_STAGE_URL"

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
	mkdir "$PROJ_DIR"/tmp 2>/dev/null
	wget -O "$PROJ_DIR"/tmp/"$BASE_STAGE" "$BASE_STAGE_URL"
fi

tar -xf "$PROJ_DIR"/tmp/"$BASE_STAGE" || exit 1

echo '#####################################################'
echo "----- Step 2. Install world"
echo '#####################################################'

# Enable overlays
mkdir -p "$TARGET_DIR"/var/db/repos/switch_overlay/
mkdir -p "$TARGET_DIR"/var/db/repos/switch_binhost_overlay/

mkdir -p "$TARGET_DIR"/etc/portage/repos.conf/
mkdir -p "$TARGET_DIR"/var/db/repos/gentoo/

cat > "$TARGET_DIR"/etc/portage/repos.conf/switch_overlay.conf << EOF
[switch]
location = /var/db/repos/switch_overlay
sync-type = git
sync-uri = https://gitlab.com/bell07/gentoo-switch_overlay
auto-sync = yes
EOF

cat > "$TARGET_DIR"/etc/portage/repos.conf/switch_binhost_overlay.conf << EOF
[switch_binhost]
location = /var/db/repos/switch_binhost_overlay
sync-type = git
sync-uri = https://gitlab.com/bell07/gentoo-switch_binhost_overlay
auto-sync = yes
EOF

function create_world() {
	source "$PROJ_DIR"/overlays/switch_binhost_overlay/app-portage/nintendo-switch-release-meta/nintendo-switch-release-meta-0.2.ebuild
	rm "$TARGET_DIR"/var/lib/portage/world
	for package in $RDEPEND; do
		echo "$package" >> "$TARGET_DIR"/var/lib/portage/world
	done
}
create_world

# Do initial setup
RELEASE_SETUP="$(cat "$CFG_DIR"/do_release_setup.sh)"
"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
# Delete catalyst settings - Migrate to new portage locations
rm /etc/portage/make.conf
rm /etc/portage/make.profile
eselect profile set default/linux/arm64/17.0

eselect profile set switch_binhost:nintendo_switch_binhost/17.0_desktop

echo "Enable en_US language support only" in /etc/locale.gen
sed -i 's/#en_US/en_US/g' /etc/locale.gen

# Update toolchain if anything needs to be compiled
emerge --usepkg --with-bdeps=n -1uj sys-devel/binutils sys-devel/gcc sys-kernel/linux-headers sys-libs/glibc
emerge --depclean sys-devel/binutils sys-devel/gcc sys-kernel/linux-headers sys-libs/glibc
. /etc/profile

# Rebuild system
emerge --buildpkg --usepkg --with-bdeps=n -evDN --jobs=5 --keep-going @system @world
emerge --depclean --with-bdeps=n

echo '#####################################################'
echo '----- Step 3. Configure'
echo '#####################################################'
$RELEASE_SETUP
eselect profile set switch:nintendo_switch/17.0/desktop
EOF

# Update and package
"$CFG_DIR"/update_release.sh noupdate
