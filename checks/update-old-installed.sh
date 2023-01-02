#!/bin/sh
emerge -va1j $(find /var/db/pkg/ -name PF -type f -ctime +180 | sed 's:^/var/db/pkg/:=:g;s:/PF$::g')
