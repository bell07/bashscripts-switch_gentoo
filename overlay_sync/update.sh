#!/bin/bash

PROJ="$(realpath $(dirname $0))"  # Absolute path
DST="$PROJ"/../overlays/switch_overlay/
PATCHDIR="$PROJ"/patches/
RSYNC="rsync -a --info=NAME --delete --exclude=.git --exclude=.gitignore"

PORTAGE=/var/db/repos/gentoo


function do_patch_keyword( ) {
	F="$1"

	CURR_KEYWORDS="$(fgrep "KEYWORDS=" "$F" )"
	if [[ "$CURR_KEYWORDS" =~ .*arm64.* ]]; then
		NEW_KEYWORDS="$CURR_KEYWORDS"
	elif [[ "$CURR_KEYWORDS" =~ .*arm.* ]]; then
		NEW_KEYWORDS="${CURR_KEYWORDS/arm/arm64}"
	elif [[ "$CURR_KEYWORDS" =~ .*amd64.* ]]; then
		NEW_KEYWORDS="${CURR_KEYWORDS/amd64/arm64}"
	elif [[ "$CURR_KEYWORDS" =~ .*x86.* ]]; then
		NEW_KEYWORDS="${CURR_KEYWORDS/x86/arm64}"
	fi

	sed -i 's/^.*KEYWORDS=.*$/'"$NEW_KEYWORDS"/g "$F"
}


function do_patch_ebuild( ) {
	EBUILD="$1"
	BASENAME1="$(basename "$EBUILD" | sed 's/[.]ebuild$//g')"
	BASENAME2="$(basename "$EBUILD" | sed 's/[-][0-9].*//g')"

	if [ -f "$PATCHDIR"/ebuild/"$BASENAME1".patch ]; then
		patch -p1 --no-backup-if-mismatch "$EBUILD" < "$PATCHDIR"/ebuild/"$BASENAME1".patch
	elif [ -f "$PATCHDIR"/ebuild/"$BASENAME2".patch ]; then
		patch -p1 --no-backup-if-mismatch "$EBUILD" < "$PATCHDIR"/ebuild/"$BASENAME2".patch
	fi
}


# Copy and patch ebuilds function
function do_move() {
	S="$1" # Source package
	T="$2" # Target (optional)
	
	if [ -z "$T" ]; then
		T="$S"
	fi

	echo "**** Move $S to $T **** "
	# Recreate whole target folder
	rm -Rf "$DST"/"$T" 2> /dev/null
	mkdir -p "$DST"/"$T"
	$RSYNC  "$SRC"/"$S"/. "$DST"/"$T"
	cd "$DST"/"$T"
	rm Manifest

	PATCHFILES="$(ls "$PATCHDIR"/source/"$(basename "$T")*" 2>/dev/null)"
	if [ -n "$PATCHFILES" ]; then
		echo "**** Copy patches ****"
		mkdir files
		cp -v "$PATCHDIR"/source/"$(basename "$T")"* files
	fi

	for F in *.ebuild; do
		echo "Apply patches to $F"
		do_patch_ebuild "$F"
		do_patch_keyword "$F"
		ebuild "$F" manifest
	done
	cd -
}


# Use kernel-build.eclass
echo "**** Sync kernel-build.eclass to $DST/eclass ****"
cp -v "$PORTAGE"/eclass/kernel-build.eclass  "$DST"/eclass
patch -p1 "$DST"/eclass/kernel-build.eclass < "$PROJ"/patches/eclass_kernel_build.patch

# Use linux-firmware from portage
SRC="$PORTAGE"
do_move "sys-kernel/linux-firmware" "sys-kernel/linux-firmware"

# Use onboard from wjn overlay
SRC="$PROJ"/wjn-overlay/
do_move "app-accessibility/onboard"
rm -v "$DST"/"app-accessibility/onboard/files/"{onboard-1.2.0-remove-duplicated-docs.patch,onboard-1.3.0-remove-duplicated-docs.patch,onboard-remove-duplicated-docs.patch}

# Use x11-misc/touchegg from waffle-builds overlay
SRC="$PROJ"/waffle-builds/
do_move "sys-apps/touchegg" "x11-misc/touchegg"

