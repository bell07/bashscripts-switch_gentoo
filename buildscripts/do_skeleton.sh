if [ -z "$1"  ]; then
	echo "Target Parameter required to build skeleton"
fi

TARGET_DIR="$1"
rm -Rf "$TARGET_DIR"

mkdir -p "$TARGET_DIR"/{boot,dev,etc,mnt,root,run,sys,proc}
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
fi
