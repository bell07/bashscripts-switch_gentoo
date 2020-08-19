#!/bin/bash
rsync -av --delete --progress packages root@orbsmart:/var/www/localhost/htdocs/pub/gentoo-switch-gcc9/
rsync -av --progress out/switch-gentoo-* root@orbsmart:/var/www/localhost/htdocs/pub/gentoo-switch-gcc9/
