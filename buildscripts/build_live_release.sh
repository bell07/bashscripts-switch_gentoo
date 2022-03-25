#!/bin/bash

CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"

# Build / Update live source environment using the "root" environment
if ! [ "$1" == "noupdate" ] ; then

	mount -v --bind "$PROJ_DIR"/live-initramfs "$PROJ_DIR"/root/mnt
	"$PROJ_DIR"/qemu-chroot.sh << EOF
export ROOT=/mnt/root
export PORTAGE_CONFIGROOT=/mnt/portage_configroot

emerge -uvtDNj world
emerge --depclean
env-update
EOF
fi

# build up live target envirinment
TARGET_DIR="$PROJ_DIR"/out/release_LIVE
rm -Rf "$TARGET_DIR"

mkdir -p "$TARGET_DIR"/{dev,mnt,run,sys,proc}
# Minimal devices https://tldp.org/LDP/lfs/LFS-BOOK-6.1.1-HTML/chapter06/devices.html
mknod -m 622 "$TARGET_DIR"/dev/console c 5 1
mknod -m 666 "$TARGET_DIR"/dev/null c 1 3
mknod -m 666 "$TARGET_DIR"/dev/zero c 1 5
mknod -m 666 "$TARGET_DIR"/dev/ptmx c 5 2
mknod -m 666 "$TARGET_DIR"/dev/tty c 5 0
mknod -m 666 "$TARGET_DIR"/dev/tty0 c 4 0
mknod -m 666 "$TARGET_DIR"/dev/tty1 c 4 1
mknod -m 444 "$TARGET_DIR"/dev/random c 1 8
mknod -m 444 "$TARGET_DIR"/dev/urandom c 1 9
chown -v root:tty "$TARGET_DIR"/dev/{console,ptmx,tty}

# Copy files from live source environment
rsync -a --exclude emerge.sh \
		--exclude /boot \
		--exclude /etc/kernel \
		--exclude /etc/portage \
		--exclude /lib/locale \
		--exclude /usr/include \
		--exclude /usr/lib/locale \
		--exclude /usr/lib/sysusers.d \
		--exclude /usr/lib64/pkgconfig \
		--exclude /usr/share/i18n \
		--exclude /usr/share/locale \
		--exclude /usr/src \
		--exclude /var/cache \
		--exclude /var/db/pkg \
		--exclude /var/lib/gentoo \
		--exclude /var/lib/portage \
		"$PROJ_DIR"/live-initramfs/root/. "$TARGET_DIR"

# Patch  and apply additional files
ln -v -s /sbin/init "$TARGET_DIR"/init

cp -v "$PROJ_DIR"/root/usr/lib/dracut/modules.d/65NintendoSwitch/pre-udev.sh "$TARGET_DIR"/usr/lib/
chmod a+x "$TARGET_DIR"/usr/lib/pre-udev.sh

cp -v root/usr/lib/gcc/aarch64-unknown-linux-gnu/*/*so* "$TARGET_DIR"/lib64/

cp -v "$PROJ_DIR"/root/etc/{passwd,shadow,group} "$TARGET_DIR"/etc/

cp -v "$PROJ_DIR"/live-initramfs/extras/switch-setup  "$TARGET_DIR"/etc/init.d/

echo "Set hostname to 'switch-live'"
echo 'hostname="switch-live"' > "$TARGET_DIR"/etc/conf.d/hostname

echo "Enable sshd root access"
sed -i 's:^#PermitRootLogin.*:PermitRootLogin yes:g' "$TARGET_DIR"/etc/ssh/sshd_config

echo "Disable ttyAMA0 tty"
sed -i 's:.*ttyAMA0.*::g' "$TARGET_DIR"/etc/inittab

# chroot target for additional configuration setup
export DEFAULT_PASSWORD='Gentoo4Switch!'

"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
echo '* Configure services'
rc-update add switch-setup sysinit
rc-update add sshd default
rc-update add wpa_supplicant default
rc-update add dhcpcd default

echo 'Set root password to '"$DEFAULT_PASSWORD"
echo -e "$DEFAULT_PASSWORD\n$DEFAULT_PASSWORD" | passwd root

EOF

# Clearup
rmdir "$TARGET_DIR"/var/cache/binpkgs

# Build SD-Card files
SDCARD_DIR="$PROJ_DIR"/out/release_LIVE_SD
rm -Rf "$SDCARD_DIR"
mkdir -p "$SDCARD_DIR"
cd "$SDCARD_DIR"

cp "$PROJ_DIR"/distfiles/switchroot-live-boot-2022-03-17.7z switchroot.7z
p7zip -d switchroot.7z

cd "$TARGET_DIR"
echo "Build initramfs"
find . -print0 | cpio --null -o --format=newc | gzip -9 > "$PROJ_DIR"/out/live_initramfs.tmp
mkimage -A arm64 -O linux -T ramdisk -C gzip -d "$PROJ_DIR"/out/live_initramfs.tmp "$SDCARD_DIR"/switchroot/live/initramfs
rm "$PROJ_DIR"/out/live_initramfs.tmp

echo "Copy kernel and dtb files"
cp -v "$PROJ_DIR"/live-initramfs/root/usr/src/linux/arch/arm64/boot/dts/tegra210-icosa.dtb "$SDCARD_DIR"/switchroot/live/
cp -v "$PROJ_DIR"/live-initramfs/root/usr/src/linux/arch/arm64/boot/Image.gz "$SDCARD_DIR"/switchroot/live/
gunzip "$SDCARD_DIR"/switchroot/live/Image.gz

echo "Copy additional files"
cp -v "$PROJ_DIR"/live-initramfs/extras/wpa_supplicant.conf "$SDCARD_DIR"/switchroot/live/

# Build the public ball
cd "$SDCARD_DIR"
rm "$PROJ_DIR"/out/pub/switch-gentoo-live-"$(date +"%Y-%m-%d")".7z
7z a "$PROJ_DIR"/out/pub/switch-gentoo-live-"$(date +"%Y-%m-%d")".7z *
