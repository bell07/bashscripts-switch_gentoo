#!/bin/bash

PROJ="$(realpath $(dirname $0))"  # Absolute path
DST="$PROJ"/../overlays/switch_overlay/
RSYNC="rsync -a --info=NAME --delete --exclude=.git --exclude=.gitignore"
PORTAGE=/var/db/repos/gentoo

# Copy and patch ebuilds function
function do_update() {
	S="$1" # Source
	T="$2" # Target (optional)
	P="$3" # Patch for each ebuild (optional)
	
	if [ -z "$T" ]; then
		T="$S"
	fi
	echo "**** Sync $S to $T **** "
	rm -Rf "$DST"/"$T" 2> /dev/null
	mkdir -p "$DST"/"$T"
	$RSYNC  "$S"/. "$DST"/"$T"
	echo "**** Patch and update manifests ****"
	cd "$DST"/"$T"
	rm Manifest
	for F in *.ebuild; do
		sed -i 's/KEYWORDS="~[a-z].*/KEYWORDS="~arm64"/g' "$F"
		sed -i 's/KEYWORDS="[a-z].*/KEYWORDS="arm64"/g' "$F"

		if [ -n "$P" ]; then
			patch -p1 "$F" < "$PROJ"/patches/"$P"
		fi

		ebuild "$F" manifest
	done
}


# Use kernel-build.eclass
echo "**** Sync kernel-build.eclass to $DST/eclass ****"
cd "$PORTAGE"
cp -v "$PORTAGE"/eclass/kernel-build.eclass  "$DST"/eclass
patch -p1 "$DST"/eclass/kernel-build.eclass < "$PROJ"/patches/eclass_kernel_build.patch

# Use linux-firmware from gentoo portage
do_update "sys-kernel/linux-firmware" "sys-kernel/linux-firmware" linux-firmware.patch

# Use onboard from wjn overlay
cd "$PROJ"/wjn-overlay/
do_update "app-accessibility/onboard"
cd "$DST"/"app-accessibility/onboard"
patch -p3  < "$PROJ"/patches/wjn-overlay-onboard.patch


# Use x11-misc/touchegg from waffle-builds overlay
cd "$PROJ"/waffle-builds/
do_update "sys-apps/touchegg" "x11-misc/touchegg" 

