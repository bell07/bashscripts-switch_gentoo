#!/bin/sh

PACKAGES=$(cat /usr/portage/packages/Packages)

cd /var/db/pkg/ || exit 1
find . -mindepth 3 -type f -name '*.ebuild' |\
sort |\
while read FILE
do
   EBUILD_INSTALLED=$(basename $FILE)
   PACKAGE=$(echo $EBUILD_INSTALLED | sed 's/[.]ebuild//g')
   CATEGORY=$(echo $FILE | cut -f2 -d'/')

   TST_INSTALLED="$(cat "$CATEGORY/$PACKAGE"/BUILD_TIME)"
   TST_BINARY="$(echo "$PACKAGES" | grep -B1 "CPV: $CATEGORY/$PACKAGE" | head -1 | sed 's/BUILD_TIME: //g')"

   if [[ "$TST_INSTALLED" != "$TST_BINARY" ]]; then
      if [[ "$1" = "-q" ]]; then
         echo ="$CATEGORY/$PACKAGE"
      else
         echo -ne ="$CATEGORY/$PACKAGE" \\t
         echo system: $(date -d@"$TST_INSTALLED" --rfc-3339=seconds), binhost: $(date -d@"$TST_BINARY" --rfc-3339=seconds)
      fi
   fi
done

