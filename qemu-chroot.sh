#!/bin/bash
PROJ_DIR="$(dirname $0)"

if [ -n "$1" ]; then
	TARGET_DIR="$1"
	shift
	if [ -n "$1" ]; then
		CMD="${*}"
	else
		CMD="/bin/bash --login"
	fi
else
	TARGET_DIR="$PROJ_DIR"/root
fi

/etc/init.d/qemu-binfmt start
/etc/init.d/distccd start

chroot-mount.sh "$TARGET_DIR"

if ! [ -d "$TARGET_DIR" ]; then
	echo "No valid root"
	exit
fi

# Mount packages folder
PACKAGES="$PROJ_DIR"/packages

if [ -d "$TARGET_DIR"/usr/portage/packages ]; then
	DST_PACKAGES="$TARGET_DIR"/usr/portage/packages
elif [ -d "$TARGET_DIR"/var/cache/binpkgs ]; then
	DST_PACKAGES="$TARGET_DIR"/var/cache/binpkgs
elif [ -d "$TARGET_DIR"/usr/portage ]; then
	DST_PACKAGES="$TARGET_DIR"/usr/portage/packages
	mkdir "$DST_PACKAGES"
else
	DST_PACKAGES="$TARGET_DIR"/var/cache/binpkgs
	mkdir -p "$DST_PACKAGES"
fi
mount -v --bind "$PACKAGES" "$DST_PACKAGES"

# Mount overlays
for OVERLAY in "$PROJ_DIR"/overlays/*; do
	TARGET_OVERLAY="$TARGET_DIR""/var/db/repos/""$(basename $OVERLAY)"
	[ -d "$TARGET_OVERLAY" ] || mkdir "$TARGET_OVERLAY"
	mount -v --bind "$OVERLAY" "$TARGET_OVERLAY"
done

# Mount checks
mount -v --bind "$PROJ_DIR"/checks "$TARGET_DIR"/checks

echo "Entering chroot ..."
cp /usr/bin/qemu-aarch64 "$TARGET_DIR"/usr/bin/
echo chroot "$TARGET_DIR" $CMD
chroot "$TARGET_DIR" $CMD
rm "$TARGET_DIR"/usr/bin/qemu-aarch64
echo "Left chroot"

chroot-umount.sh "$TARGET_DIR"

# Umount remaining mounts
mount | grep "$TARGET_DIR" | while read x on DIR rest; do echo $DIR; done | sort -r | while read MOUNT; do
	umount -v "$MOUNT"
done
