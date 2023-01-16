#!/bin/bash

PROJ="$(realpath $(dirname $0))"  # Absolute path
DST="$PROJ"/../overlays/switch_overlay/
PATCHDIR="$PROJ"/patches
RSYNC="rsync -q -a --info=NAME --delete --exclude=.git --exclude=.gitignore"

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

	if [ -n "$NEW_KEYWORDS" ]; then
		sed -i 's/^.*KEYWORDS=.*$/'"$NEW_KEYWORDS"/g "$F"
	fi
}


function do_patch_ebuild( ) {
	EBUILD="$1"
	BASENAME1="$(basename "$EBUILD" | sed 's/[.]ebuild$//g')"

	SEL_PATCH=""
	# Try exact version
	if [[ -f "$PATCHDIR"/ebuild/"$BASENAME1".patch ]]; then
		SEL_PATCH="$BASENAME1".patch
	else
		# Try without version / Search for best match
		BASENAME2="$(basename "$EBUILD" | sed 's/[-][0-9].*//g')"
		if [[ -f "$PATCHDIR"/ebuild/"$BASENAME2".patch ]]; then
			SEL_PATCH="$BASENAME2".patch
		fi

		for patch in "$PATCHDIR"/ebuild/"$BASENAME2"*; do
			if [[ "$SEL_PATCH" == "" ]] || ! [[ "$(basename "$patch")" > "$BASENAME1".patch ]]; then
				SEL_PATCH="$(basename "$patch")"
			fi
		done
	fi

	if [ -f "$PATCHDIR"/ebuild/"$SEL_PATCH" ]; then
		echo "apply patch $SEL_PATCH to $EBUILD"
		patch -p1 --no-backup-if-mismatch "$EBUILD" < "$PATCHDIR"/ebuild/"$SEL_PATCH" 
	fi

	if [[ "$SRC" == "$PORTAGE" ]]; then
		CATEGORY="$(basename "$(dirname "$(realpath .)")")"
		echo add "=$CATEGORY/$BASENAME1" to package.unmask
		echo "=$CATEGORY/$BASENAME1" >> "$DST"/profiles/nintendo_switch/package.unmask
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

	PATCHFILES="$(ls "$PATCHDIR"/source/"$(basename "$T")"/* 2>/dev/null)"
	if [ -n "$PATCHFILES" ]; then
		echo "**** Copy patches ****"
		mkdir files 2> /dev/null
		cp -v "$PATCHDIR"/source/"$(basename "$T")/"* files
	fi
	for F in *.ebuild; do
		do_patch_ebuild "$F"
		do_patch_keyword "$F"
		ebuild "$F" manifest >/dev/null
	done
	cd - > /dev/null
}

# Use kernel-build.eclass
echo "**** Sync kernel-build.eclass to $DST/eclass ****"
cp -v "$PORTAGE"/eclass/kernel-build.eclass  "$DST"/eclass
patch -p1 --no-backup-if-mismatch "$DST"/eclass/kernel-build.eclass < "$PROJ"/patches/eclass_kernel_build.patch

SRC="$PORTAGE"
rm "$DST"/profiles/nintendo_switch/package.unmask 2>/dev/null
do_move dev-qt/qtcore
do_move net-wireless/bluez
do_move sys-apps/shadow
do_move sys-apps/systemd-utils
do_move x11-libs/libdrm

# Use onboard from wjn overlay
SRC="$PROJ"/earshark/
do_move app-accessibility/onboard

# Use x11-misc/touchegg from waffle-builds overlay
SRC="$PROJ"/waffle-builds/
do_move sys-apps/touchegg x11-misc/touchegg

SRC="$PROJ"/x11
do_move app-benchmarks/glmark2

# Libretro / Retroarch from menelkir
SRC="$PROJ"/menelkir
cp -v "$SRC"/eclass/libretro*  "$DST"/eclass

do_move dev-lang/rgbds
do_move games-emulation/3dengine-libretro
do_move games-emulation/81-libretro
do_move games-emulation/atari800-libretro
do_move games-emulation/bk-libretro
do_move games-emulation/blastem-libretro
do_move games-emulation/bluemsx-libretro
do_move games-emulation/boom3-libretro
do_move games-emulation/bsnes-mercury-performance-libretro
do_move games-emulation/bsnes2014-performance-libretro
do_move games-emulation/cap32-libretro
do_move games-emulation/chailove-libretro
do_move games-emulation/citra-libretro
do_move games-emulation/craft-libretro
do_move games-emulation/crocods-libretro
do_move games-emulation/daphne-libretro
do_move games-emulation/desmume-libretro
do_move games-emulation/dinothawr-libretro
do_move games-emulation/dolphin-libretro
do_move games-emulation/dosbox-svn-libretro
do_move games-emulation/ecwolf-libretro
do_move games-emulation/fbalpha2012-libretro
do_move games-emulation/fbalpha-libretro
do_move games-emulation/fbneo-libretro
do_move games-emulation/fceu-next-libretro
do_move games-emulation/ffmpeg-libretro
do_move games-emulation/flycast-libretro
do_move games-emulation/fmsx-libretro
do_move games-emulation/freechaf-libretro
do_move games-emulation/freeintv-libretro
do_move games-emulation/frodo-libretro
do_move games-emulation/fuse-libretro
do_move games-emulation/gambatte-libretro
do_move games-emulation/gearboy-libretro
do_move games-emulation/gearsystem-libretro
do_move games-emulation/genesis_plus_gx-libretro
do_move games-emulation/genesis_plus_gx_wide-libretro
do_move games-emulation/glsl-shaders
do_move games-emulation/gme-libretro
do_move games-emulation/gong-libretro
do_move games-emulation/gpsp-libretro
do_move games-emulation/gw-libretro
do_move games-emulation/handy-libretro
do_move games-emulation/hatari-libretro
do_move games-emulation/hbmame-libretro
do_move games-emulation/libretro-common-overlays
do_move games-emulation/libretro-common-shaders
do_move games-emulation/libretro-database
do_move games-emulation/libretro-info
do_move games-emulation/libretro-meta
do_move games-emulation/lowresnx-libretro
do_move games-emulation/lutro-libretro
do_move games-emulation/mame2000-libretro
do_move games-emulation/mame2003-libretro
do_move games-emulation/mame2010-libretro
do_move games-emulation/mame2015-libretro
do_move games-emulation/mame-libretro
do_move games-emulation/mednafen-bsnes-libretro
do_move games-emulation/mednafen-gba-libretro
do_move games-emulation/mednafen-lynx-libretro
do_move games-emulation/mednafen-ngp-libretro
do_move games-emulation/mednafen-pce-fast-libretro
do_move games-emulation/mednafen-pce-libretro
do_move games-emulation/mednafen-pcfx-libretro
do_move games-emulation/mednafen-psx-libretro
do_move games-emulation/mednafen-psx-hw-libretro
do_move games-emulation/mednafen-saturn-libretro
do_move games-emulation/mednafen-supafaust-libretro
do_move games-emulation/mednafen-supergrafx-libretro
do_move games-emulation/mednafen-vb-libretro
do_move games-emulation/mednafen-wswan-libretro
do_move games-emulation/melonds-libretro
do_move games-emulation/meowpc98-libretro
do_move games-emulation/mesen-libretro
do_move games-emulation/mesens-libretro
do_move games-emulation/mess2015-libretro
do_move games-emulation/meteor-libretro
do_move games-emulation/mgba-libretro
do_move games-emulation/mrboom-libretro
do_move games-emulation/mu-libretro
do_move games-emulation/mupen64next-libretro
do_move games-emulation/nekop2-libretro
do_move games-emulation/neocd-libretro
do_move games-emulation/np2kai-libretro
do_move games-emulation/nxengine-libretro
do_move games-emulation/o2em-libretro
do_move games-emulation/oberon-libretro
do_move games-emulation/openlara-libretro
do_move games-emulation/opera-libretro
do_move games-emulation/parallel_n64-libretro
do_move games-emulation/pcsx-rearmed-libretro
do_move games-emulation/picodrive-libretro
do_move games-emulation/play-libretro
do_move games-emulation/pocketcdg-libretro
do_move games-emulation/pokemini-libretro
do_move games-emulation/potator-libretro
do_move games-emulation/ppsspp-libretro
do_move games-emulation/prboom-libretro
do_move games-emulation/prosystem-libretro
do_move games-emulation/puae-libretro
do_move games-emulation/px68k-libretro
do_move games-emulation/quasi88-libretro
do_move games-emulation/quicknes-libretro
do_move games-emulation/race-libretro
do_move games-emulation/reminiscence-libretro
do_move games-emulation/retro8-libretro
do_move games-emulation/retroarch
do_move games-emulation/retroarch-assets
do_move games-emulation/retroarch-joypad-autoconfig
do_move games-emulation/sameboy-libretro
do_move games-emulation/scummvm-libretro
do_move games-emulation/slang-shaders
do_move games-emulation/smsplus-libretro
do_move games-emulation/snes9x2002-libretro
do_move games-emulation/snes9x2005-libretro
do_move games-emulation/snes9x2010-libretro
do_move games-emulation/squirreljme-libretro
do_move games-emulation/stella2014-libretro
do_move games-emulation/stonesoup-libretro
do_move games-emulation/swanstation-libretro
do_move games-emulation/tgbdual-libretro
do_move games-emulation/theodore-libretro
do_move games-emulation/thepowdertoy-libretro
do_move games-emulation/tic80-libretro
do_move games-emulation/tyrquake-libretro
do_move games-emulation/uzem-libretro
do_move games-emulation/vbam-libretro
do_move games-emulation/vba-next-libretro
do_move games-emulation/vecx-libretro
do_move games-emulation/vemulator-libretro
do_move games-emulation/vice-x128-libretro
do_move games-emulation/vice-x64-libretro
do_move games-emulation/vice-x64sc-libretro
do_move games-emulation/vice-xcbm2-libretro
do_move games-emulation/vice-xcbm5x0-libretro
do_move games-emulation/vice-xpet-libretro
do_move games-emulation/vice-xplus4-libretro
do_move games-emulation/vice-xscpu64-libretro
do_move games-emulation/vice-xvic-libretro
do_move games-emulation/virtualjaguar-libretro
do_move games-emulation/vitaquake2-libretro
do_move games-emulation/vitaquake3-libretro
do_move games-emulation/vitavoyager-libretro
do_move games-emulation/x1-libretro
do_move games-emulation/xrick-libretro
do_move games-emulation/yabause-libretro

# Nice game selection UI
SRC="$PROJ"/guru
do_move games-util/gamehub


# Libretro / Retroarch from menelkir
SRC="$PROJ"/bell07_overlay
do_move x11-misc/dock-hotplug
