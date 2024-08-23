if [ -z "$1"  ]; then
	echo "Target Parameter required to build skeleton"
fi

TARGET_DIR="$1"
rm -Rf "$TARGET_DIR"

mkdir -p "$TARGET_DIR"/{boot,dev,etc,mnt,root,run,sys,proc,usr/bin,usr/lib,usr/lib64}
ln -s usr/bin "$TARGET_DIR"/bin
ln -s usr/bin "$TARGET_DIR"/sbin
ln -s bin "$TARGET_DIR"/usr/sbin
ln -s usr/lib "$TARGET_DIR"/lib
ln -s usr/lib64 "$TARGET_DIR"/lib64

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

if [ "$2" == "portage" ]; then
	mkdir -p "$TARGET_DIR"/etc/portage/repos.conf
	mkdir -p "$TARGET_DIR"/var/cache/binpkgs
	mkdir -p "$TARGET_DIR"/var/cache/distfiles
	mkdir -p "$TARGET_DIR"/var/db/repos/gentoo
	mkdir -p "$TARGET_DIR"/var/db/repos/switch_overlay

# Required for cross and for chroot emerge
	mkdir -p "$TARGET_DIR"/usr/share/openpgp-keys
	cp -v /usr/share/openpgp-keys/gentoo-release.asc "$TARGET_DIR"/usr/share/openpgp-keys/gentoo-release.asc
fi
