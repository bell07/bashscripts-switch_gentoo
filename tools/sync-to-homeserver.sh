#!/bin/bash
TOOLS_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$TOOLS_DIR")"


mount -o bind "$PROJ_DIR"/packages "$PROJ_DIR"/out/pub/packages

echo "Sync to homer"
rsync -av --delete --progress "$PROJ_DIR"/out/pub/. admin@homer:/media/bigdata/pub/gentoo-switch/
umount "$PROJ_DIR"/out/pub/packages/

