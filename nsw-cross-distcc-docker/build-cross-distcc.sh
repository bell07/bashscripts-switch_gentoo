#!/bin/bash

cd "$(realpath "$(dirname $0)")"

echo "Prepare build environment"
rm -Rf build 2>/dev/null
mkdir build

cp -a cross-distcc-files build
cp -a ../overlays/switch_overlay/sys-kernel/linux-headers/ build
cp -a ../overlays/switch_overlay/sys-libs/glibc/ build

docker buildx create --name nsw-cross-distcc
docker buildx use nsw-cross-distcc
docker buildx inspect

docker buildx build -f Dockerfile -t nsw-cross-distcc --load build $@

docker buildx use default
