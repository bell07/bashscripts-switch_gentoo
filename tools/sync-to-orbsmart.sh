#!/bin/bash
mount -o bind packages out/pub/packages
rsync -av --delete --progress out/pub/. admin@orbsmart:/var/www/localhost/htdocs/pub/gentoo-switch/
umount out/pub/packages/
