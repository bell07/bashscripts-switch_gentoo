#!/bin/sh
I=/tmp/ebuild.installed
C=/tmp/ebuild.portage
cleanup () {
   sed 's/ *#.*//g'  $1 | \
   grep -v   $1   \
   -e "^$"   \
   -e 'KEYWORDS='   \
   -e 'HOMEPAGE='   \
   -e 'LICENSE='   \
   -e 'SRC_URI='   \
   -e 'eerror'   \
   -e 'einfo'   \
   -e 'ewarn'   \
   -e 'elog'
}
cd /var/db/pkg/ || exit 1
find . -mindepth 3 -type f -name '*.ebuild' |\
sort |\
while read FILE
do
   EBUILD_INSTALLED=$(basename $FILE)
   PACKAGE=$(echo $EBUILD_INSTALLED | sed 's/[.]ebuild//g')
   CATEGORIE=$(echo $FILE | cut -f2 -d'/')
   REPO="$(cat "$(dirname $FILE)/repository")"
   [[ "$REPO" == "gentoo" ]] && REPO_PATH=/usr/portage
   [[ "$REPO" == "switch" ]] && REPO_PATH=/var/db/repos/switch_overlay
   [[ "$REPO" == "switch_binhost" ]] && REPO_PATH=/var/db/repos/switch_binhost_overlay

   EBUILD_PORTAGE=$(ls "$REPO_PATH"/"$CATEGORIE"/$(echo $PACKAGE | cut -f1 -d'-')*/$EBUILD_INSTALLED 2>/dev/null)
   [[ -f $EBUILD_PORTAGE ]] || continue

   cleanup $FILE    > $I
   cleanup $EBUILD_PORTAGE   > $C

   DIFF=$(diff $I $C 2>/dev/null)
   if [[ $? -eq 1 ]]; then
   if [[ "$1" = "-q" ]]; then
      echo "=$CATEGORIE/$EBUILD_INSTALLED" | sed 's/\.ebuild//g'
   else
      echo -e "$CATEGORIE/$(basename $(dirname $EBUILD_PORTAGE))\t$EBUILD_INSTALLED"
   fi
   [[ "$1" = "-v" ]] && echo -e "$DIFF\n"
   fi

   rm $I $C
done

