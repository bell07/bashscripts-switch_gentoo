#!/bin/bash
rsync -av --delete --progress packages admin@orbsmart:/var/www/localhost/htdocs/pub/gentoo-switch/
rsync -av --progress out/switch-gentoo-* admin@orbsmart:/var/www/localhost/htdocs/pub/gentoo-switch/
