#!/bin/sh
CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"

BASE_STAGE=stage3-arm64-20200609.tar.bz2
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

#  mirgate to new portage location
mkdir "$TARGET_DIR"/var/db/repos
rm -Rf "$TARGET_DIR"/usr/portage
mkdir -p "$TARGET_DIR"/var/db/repos/gentoo
mkdir -p "$TARGET_DIR"/var/cache/distfiles
mkdir -p "$TARGET_DIR"/var/cache/binpkgs

# Enable overlays
mkdir -p "$TARGET_DIR"/var/db/repos/switch_overlay
mkdir -p "$TARGET_DIR"/var/db/repos/switch_binhost_overlay

mkdir -p "$TARGET_DIR"/etc/portage/repos.conf/
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
ln -s /var/db/repos/gentoo/profiles/default/linux/arm64/17.0 /etc/portage/make.profile
sed -i 's:/usr/portage/distfiles:/var/cache/distfiles:g' /usr/share/portage/config/make.globals
sed -i 's:/usr/portage/packages:/var/cache/binpkgs:g' /usr/share/portage/config/make.globals

eselect profile set switch_binhost:nintendo_switch_binhost/17.0_desktop_base_gcc9

echo "Enable en_US language support only" in /etc/locale.gen
sed -i 's/#en_US/en_US/g' /etc/locale.gen

# Update toolchain if anything needs to be compiled
emerge --usepkg --with-bdeps=n -1uj sys-devel/binutils sys-devel/gcc:9.3.0 sys-kernel/linux-headers sys-libs/glibc
emerge --depclean sys-devel/binutils sys-devel/gcc sys-kernel/linux-headers sys-libs/glibc
. /etc/profile

# Rebuild system
emerge --buildpkg --usepkg --with-bdeps=n -evDN --jobs=5 @system @world
emerge --depclean --with-bdeps=n

echo '#####################################################'
echo '----- Step 3. Configure'
echo '#####################################################'
$RELEASE_SETUP

eselect profile set switch:nintendo_switch/17.0/desktop
EOF

# Update and package
"$CFG_DIR"/update_release.sh noupdate
