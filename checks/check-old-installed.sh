#!/bin/sh
find /var/db/pkg/ -name PF -type f -ctime +180 -exec ls -l {} \;
