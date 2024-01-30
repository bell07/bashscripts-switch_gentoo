#!/bin/bash

CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"
KERNEL_VERSION=4.9.140.512-l4t-gentoo-dist

# build up live target envirinment
TARGET_DIR="$PROJ_DIR"/live-initramfs-build/root
STAGE_CONFIGROOT="$PROJ_DIR"/live-initramfs-build/portage_configroot

# Build / Update live source environment using the "root" environment
if [ "$1" == "rebuild" ] ; then
	"$CFG_DIR"/do_skeleton.sh "$TARGET_DIR"
fi

if ! [ "$1" == "noupdate" ]; then
	# Update system
	ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$STAGE_CONFIGROOT" \
		aarch64-unknown-linux-gnu-emerge -uvDN --jobs=5 \
		--buildpkg n --binpkg-changed-deps n \
			@system net-misc/dhcp

	# Update world
	ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$STAGE_CONFIGROOT" \
		aarch64-unknown-linux-gnu-emerge -uvDN --jobs=5 \
		--buildpkg n --binpkg-changed-deps n \
			sys-kernel/nintendo-switch-l4t-kernel \
			sys-firmware/jetson-tx1-firmware \
			sys-apps/nintendo-switch-meta \
			sys-libs/gentoo-config-files \
			app-misc/my-world-meta

	# Cleanup
	ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$STAGE_CONFIGROOT" \
		aarch64-unknown-linux-gnu-emerge --depclean --with-bdeps=n
fi

# Print installed output
echo "Installed packages:"
ROOT="$TARGET_DIR" PORTAGE_CONFIGROOT="$STAGE_CONFIGROOT" CROSS_CMD="eix" aarch64-unknown-linux-gnu-ebuild -cI

# build up live target envirinment
echo "Copy selected files to release folder"
RELEASE_DIR="$PROJ_DIR"/out/release_LIVE
rm -Rf "$RELEASE_DIR"

rsync -a --exclude emerge.sh \
		--exclude /_ldd.list \
		--exclude /boot \
		--exclude /etc/dracut.conf.d \
		--exclude /etc/kernel \
		--exclude /etc/logrotate.d \
		--exclude /etc/portage \
		--exclude /etc/skel \
		--exclude /lib64 \
		--exclude /lib/locale \
		--exclude /lib/systemd/system \
		--exclude /usr/aarch64-unknown-linux-gnu \
		--exclude /usr/include \
		--exclude /usr/lib/dracut \
		--exclude /usr/lib/gcc \
		--exclude /usr/lib/locale \
		--exclude '/usr/lib/python*/test/' \
		--exclude /usr/lib/sysusers.d \
		--exclude /usr/lib64 \
		--exclude /usr/libexec/gcc \
		--exclude /usr/local \
		--exclude /usr/share/bash-competitions \
		--exclude /usr/share/doc \
		--exclude /usr/share/gcc-config \
		--exclude /usr/share/gcc-data \
		--exclude /usr/share/gdb \
		--exclude /usr/share/gtk-doc \
		--exclude /usr/share/i18n \
		--exclude /usr/share/icons \
		--exclude /usr/share/info \
		--exclude /usr/share/locale \
		--exclude /usr/share/man \
		--exclude /usr/share/openpgp-keys \
		--exclude /usr/sdcard1 \
		--exclude /usr/src \
		--exclude /var/cache \
		--exclude /var/db/pkg \
		--exclude /var/lib/gentoo \
		--exclude /var/lib/portage \
		--exclude '[.]keep_*' \
		--exclude '[_]_pycache__' \
		"$TARGET_DIR"/. "$RELEASE_DIR"

# Collect and copy all required libraries
 "$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR" << EOF
	ldconfig
	find . -executable -type f -exec ldd {} \; 2> /dev/null > /_ldd.list
EOF

mkdir "$RELEASE_DIR"/lib64
for file in $(cat "$TARGET_DIR"/_ldd.list | awk 'NF == 4 { print $3 }' | sort -u); do
	cp "$TARGET_DIR"/"$file" "$RELEASE_DIR"/lib64
done

echo "Patch  and apply additional files"
ln -v -s /sbin/init "$RELEASE_DIR"/init

cp -v "$PROJ_DIR"/root/usr/lib/dracut/modules.d/65NintendoSwitch/pre-udev.sh "$RELEASE_DIR"/usr/lib/
cp -v "$PROJ_DIR"/live-initramfs-build/extras/switch-setup  "$RELEASE_DIR"/etc/init.d/

echo "Set hostname to 'switch-live'"
echo 'hostname="switch-live"' > "$RELEASE_DIR"/etc/conf.d/hostname

echo "Enable sshd root access"
sed -i 's:^#PermitRootLogin.*:PermitRootLogin yes:g' "$RELEASE_DIR"/etc/ssh/sshd_config

echo "Disable ttyAMA0 tty"
sed -i 's:.*ttyAMA0.*::g' "$RELEASE_DIR"/etc/inittab
echo "Clear console after boot (fix missplaced messages)"
sed -i 's:--noclear ::g' "$RELEASE_DIR"/etc/inittab

# chroot target for additional configuration setup
export DEFAULT_PASSWORD='Gentoo4Switch!'

"$PROJ_DIR"/qemu-chroot.sh "$RELEASE_DIR"  << EOF
systemd-tmpfiles --create
find . -mount -xtype l -exec rm {} \;
echo '* Configure services'
rc-update add switch-setup sysinit
rc-update add sshd default
#rc-update add wpa_supplicant default
#rc-update add dhcpcd default
rc-update add gpm default
ln -s net.lo /etc/init.d/net.wlp1s0

echo 'Set root password to '"$DEFAULT_PASSWORD"
echo "root:$DEFAULT_PASSWORD" | chpasswd
EOF

# Build SD-Card files
SDCARD_DIR="$PROJ_DIR"/out/release_LIVE_SD
rm -Rf "$SDCARD_DIR"
mkdir -p "$SDCARD_DIR"/switchroot/live/
mkdir -p "$SDCARD_DIR"/bootloader/ini/

cd "$RELEASE_DIR"
echo "Build initramfs"
find . -print0 | cpio --null -o --format=newc | gzip -9 > "$PROJ_DIR"/out/live_initramfs.tmp
mkimage -A arm64 -O linux -T ramdisk -C gzip -d "$PROJ_DIR"/out/live_initramfs.tmp "$SDCARD_DIR"/switchroot/live/initramfs
rm "$PROJ_DIR"/out/live_initramfs.tmp

echo "Copy kernel boot files"
cp -v "$PROJ_DIR"/root/boot/uImage-"$KERNEL_VERSION" "$SDCARD_DIR"/switchroot/live/uImage
cp -v "$PROJ_DIR"/root/boot/nx-plat-"$KERNEL_VERSION".dtimg "$SDCARD_DIR"/switchroot/live/nx-plat.dtimg
cp -v "$PROJ_DIR"/root/usr/share/sdcard1/switchroot/gentoo/* "$SDCARD_DIR"/switchroot/live/
cp -v "$PROJ_DIR"/live-initramfs-build/extras/L4T-live.ini "$SDCARD_DIR"/bootloader/ini/

echo "Copy additional files"
cp -v "$PROJ_DIR"/live-initramfs-build/extras/wpa_supplicant.conf "$SDCARD_DIR"/switchroot/live/

# Build the public ball
cd "$SDCARD_DIR"
rm "$PROJ_DIR"/out/pub/switch-gentoo-live-"$(date +"%Y-%m-%d")".7z
7z a "$PROJ_DIR"/out/pub/switch-gentoo-live-"$(date +"%Y-%m-%d")".7z *
