#!/bin/bash
find packages -type f -ctime +180 -exec ls -l {} \;
