#!/bin/sh

CFG_DIR="$(dirname $0)"

TARGET_DIR="$(dirname "$CFG_DIR")"/../root

cp -av "$CFG_DIR"/base/* "$TARGET_DIR"
cp -av "$CFG_DIR"/release/* "$TARGET_DIR"
cp -av "$CFG_DIR"/buildhost/* "$TARGET_DIR"

echo "Add packages to world"
cat >> "$TARGET_DIR"/var/lib/portage/world <<EOL
app-portage/cpuid2cpuflags
app-portage/gentoolkit
app-portage/eix
sys-devel/distcc
EOL
mkdir -p "$TARGET_DIR"/usr/portage/packages

echo "Configure make.conf for buildpkg and distcc"
cat >> "$TARGET_DIR"/etc/portage/make.conf <<EOL

## Buldhost related
FEATURES="\$FEATURES buildpkg"         # Create packages for binhost
FEATURES="\$FEATURES -pid-sandbox"     # emerge fails on my system if set
FEATURES="\$FEATURES distcc"           # Move compiling to crossdev outsite emulation

MAKEOPTS="-j10"                       # Useful for local distcc (I think so)
EOL
