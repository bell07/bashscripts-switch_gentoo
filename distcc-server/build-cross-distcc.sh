#!/bin/bash

cd "$(realpath "$(dirname $0)")"


export RUN_CACHED="RUN --mount=type=cache,target=/var/cache \
--mount=type=cache,target=/var/db/repos/gentoo \
--mount=type=tmpfs,target=/var/log \
--mount=type=tmpfs,target=/var/tmp"

echo "Prepare build environment"
rm -Rf build 2>/dev/null
mkdir build
envsubst < Dockerfile.template > build/Dockerfile
cp -a cross-distcc-files build
cp -a ../overlays/switch_overlay/sys-kernel/linux-headers/ build
cp -a ../overlays/switch_overlay/sys-libs/glibc/ build

docker buildx create --name nsw-cross-distcc
docker buildx use nsw-cross-distcc
docker buildx inspect

docker buildx build -f build/Dockerfile -t nsw-cross-distcc --load build $@

docker buildx use default
