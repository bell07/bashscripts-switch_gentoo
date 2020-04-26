#!/bin/sh
find /var/db/pkg/ -name PF -type f -ctime +90 -exec ls -l {} \;
