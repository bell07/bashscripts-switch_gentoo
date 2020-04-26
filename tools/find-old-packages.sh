#!/bin/bash
find packages -type f -ctime +90 -exec ls -l {} \;
