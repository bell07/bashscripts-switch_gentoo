#!/bin/sh

CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"
TARGET_DIR="$(dirname "$CFG_DIR")"/root

echo "-- Step 1: Update buildhost root configuration"
# Update distcc
mkdir -p "$TARGET_DIR"/etc/distcc/
cat > "$TARGET_DIR"/etc/distcc/hosts<<EOL
# Use TCP connection to crossdev compiler
127.0.0.1:3632
EOL

BUILDHOST_PACKAGES="app-portage/gentoolkit sys-devel/distcc"

echo "-- Step 2: Install/Update additional packages"
"$PROJ_DIR"/qemu-chroot.sh "$TARGET_DIR"  << EOF
FEATURES="-pid-sandbox buildpkg" emerge --usepkg --with-bdeps=n --noreplace -v --jobs=5 $BUILDHOST_PACKAGES
EOF

echo "-- Step 3: Configure make.conf for buildpkg and distcc"
if [ -f "$TARGET_DIR"/etc/portage/make.conf ]; then
	MAKECONF="$(fgrep -x '## Buldhost related' -B 1000 -m1 "$TARGET_DIR"/etc/portage/make.conf | head -n-1)"
fi

cat > "$TARGET_DIR"/etc/portage/make.conf <<EOL
$MAKECONF

## Buldhost related
FEATURES="\$FEATURES buildpkg"         # Create packages for binhost
FEATURES="\$FEATURES -pid-sandbox"     # emerge fails on my system if set
FEATURES="\$FEATURES distcc"           # Move compiling to crossdev outsite emulation

MAKEOPTS="-j10"                       # Useful for local distcc (I think so)
EOL
