#!/bin/bash

echo "do uploads"
drive clashes -fix -fix-mode trash -no-prompt

drive push -no-prompt -ignore-conflict packages
drive pub packages

#echo "zip packages"
#rm packages.zip
#zip -r packages.zip packages

#drive push -no-prompt -m -ignore-conflict packages.zip
#drive pub packages.zip

#for file in out/switch*; do
#	drive push -no-prompt -m -ignore-conflict "$file"
#	drive pub "$(basename "$file")"
#done
