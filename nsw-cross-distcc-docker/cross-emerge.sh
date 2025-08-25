#!/bin/sh

DOCKER_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"

if [ -z "$ROOT" ] || [ -z "$PORTAGE_CONFIGROOT" ]; then
	echo "environment variables ROOT and PORTAGE_CONFIGROOT required to launch cross-emerge"
	exit 1
fi

MY_ROOT="$(realpath "$ROOT")"
MY_PORTAGE_CONFIGROOT="$(realpath "$PORTAGE_CONFIGROOT")"
unset ROOT PORTAGE_CONFIGROOT

CONTAINER_NAME="cross-$(basename "${MY_ROOT,,}")"

LAUNCH="/usr/bin/aarch64-unknown-linux-gnu-emerge $@"

if [ -z "$(docker ps -a --format '{{.Names}}' | grep "^${CONTAINER_NAME}$")" ]; then
echo "$CONTAINER_NAME"
   docker run -itd --rm --name "$CONTAINER_NAME" \
       --tmpfs /sys/fs/cgroup \
       --entrypoint=/usr/bin/bash \
       --env ROOT=/cross_root \
       --env PORTAGE_CONFIGROOT=/cross_configroot \
       --env FEATURES="-ipc-sandbox -network-sandbox -pid-sandbox" \
       --volume "$MY_ROOT":/cross_root \
       --volume "$MY_PORTAGE_CONFIGROOT":/cross_configroot \
       --volume /var/db/repos/gentoo:/var/db/repos/gentoo \
       --volume /var/db/repos/bell07:/var/db/repos/bell07 \
       --volume "$PROJ_DIR"/overlays/switch_overlay:/var/db/repos/switch_overlay \
       --volume "$PROJ_DIR"/packages:/packages \
        nsw-cross-distcc
fi

docker exec -it "$CONTAINER_NAME" $LAUNCH
