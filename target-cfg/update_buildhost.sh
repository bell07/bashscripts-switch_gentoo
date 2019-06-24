#!/bin/sh

TARGET_DIR=root

cp -av target-cfg/base/* "$TARGET_DIR"
cp -av target-cfg/release/* "$TARGET_DIR"
cp -av target-cfg/buildhost/* "$TARGET_DIR"

mkdir -p "$TARGET_DIR"/usr/portage/packages

echo "Configure make.conf for buildpkg and distcc"
cat >> "$TARGET_DIR"/etc/portage/make.conf <<EOL

## Buldhost related
FEATURES="\$FEATURES buildpkg"         # Create packages for binhost
FEATURES="\$FEATURES -pid-sandbox"     # emerge fails on my system if set
FEATURES="\$FEATURES distcc"           # Move compiling to crossdev outsite emulation

MAKEOPTS="-j10"                       # Useful for local distcc (I think so)
EOL
