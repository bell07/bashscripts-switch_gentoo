#!/bin/bash
CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"
BUILD_DIR="$PROJ_DIR"/bootstack-build
DOCKER_IMG=registry.gitlab.com/switchroot/bootstack/bootstack-build-scripts

/etc/init.d/docker start

mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

docker pull "$DOCKER_IMG"
docker run -it --rm -e CPUS=$(nproc) -e DISTRO=gentoo -v "${PWD}"/out:/out "$DOCKER_IMG"
mv -v "$BUILD_DIR"/out/switchroot-gentoo-boot* "$PROJ_DIR"/distfiles
