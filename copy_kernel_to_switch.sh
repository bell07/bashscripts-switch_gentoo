#!/bin/sh

## Version to sync
KERNEL_VERSION=4.9.112

## Switch conneted trough USB-network
SWITCH=192.168.76.1

## Switch connected trough WIFI network
#SWITCH=nintendo-switch

## Use Network above
#URI=root@"$SWITCH":

## SD-Card is mounted on PC
URI=/run/media/user/gentoo-switch

## Sync all modules
rsync -avz --delete /home/user/switch_gentoo/root/lib/modules/"$KERNEL_VERSION"-nintendo "$URI"/lib/modules/

## Sync boot files
rsync -avz /home/user/switch_gentoo/root/boot/*"$KERNEL_VERSION"* "$URI"/boot/
