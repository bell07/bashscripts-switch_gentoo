#!/bin/sh

PROJ_DIR="$(dirname $0)"

## Version to sync
KERNEL_VERSION=4.9.112.30.3-nintendo-switch-l4t

## Switch conneted trough USB-network
#SWITCH=192.168.76.1

## Switch connected trough WIFI network
SWITCH=nintendo-switch

## Use Network above
#URI=root@"$SWITCH":

## SD-Card is mounted on PC
## Mounted by udev for user, gentoo root partition have "gentoo-switch" label
URI="$(realpath /run/media/*/gentoo-switch | head -n 1)"

## Sync all modules
rsync -avz --delete "$PROJ_DIR"/root/lib/modules/"$KERNEL_VERSION" "$URI"/lib/modules/

## Sync boot files
rsync -avz "$PROJ_DIR"/root/boot/coreboot.rom "$PROJ_DIR"/root/boot/boot.scr "$PROJ_DIR"/root/boot/*$KERNEL_VERSION*  "$URI"/boot/
