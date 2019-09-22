#!/bin/bash

[[ -z "$1" ]] && echo 'Parameter "switch", "binary" or "both" required to select overlay that should be checked' && exit 1

echo "Prepare check"
cd /etc/portage/

[[ -h make.conf ]] && rm make.conf
[[ -f make.conf ]] && mv make.conf make.conf.bak

if [ "$1" == "switch" ] || [ "$1" == "both" ] ; then
	echo "Check nintendo_switch profile"
	eselect profile set default/linux/arm64/17.0/desktop
	ln -s /var/db/repos/switch_overlay/profiles/nintendo_switch/make.defaults make.conf
	for pkg in /var/db/repos/switch_overlay/profiles/nintendo_switch/package.*; do ln -s "$pkg" .; done

	eix-test-obsolete

	rm package.*
	rm make.conf
fi

if [ "$1" == "binary" ] || [ "$1" == "both" ] ; then
	echo "Check nintendo_binhost_switch profile"
	eselect profile set switch:nintendo_switch/17.0/desktop

	ln -s /var/db/repos/switch_binhost_overlay/profiles/nintendo_switch_binhost/make.defaults make.conf
	for pkg in /var/db/repos/switch_binhost_overlay/profiles/nintendo_switch_binhost/package.*; do ln -s "$pkg" .; done

	eix-test-obsolete

	rm package.*
	rm make.conf
fi

echo "Restore binhost"
mv make.conf.bak make.conf
eselect profile set switch_binhost:nintendo_switch_binhost/17.0_desktop
