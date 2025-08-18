#!/bin/bash
mount -o bind packages out/pub/packages
#echo "Sync to orbsmart"
#rsync -av --delete --progress out/pub/. admin@orbsmart:/var/www/localhost/htdocs/pub/gentoo-switch/

echo "Sync to homer"
rsync -av --delete --progress out/pub/. admin@homer:/media/bigdata/pub/gentoo-switch/
umount out/pub/packages/

