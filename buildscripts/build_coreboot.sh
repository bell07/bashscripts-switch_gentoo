#!/bin/bash

echo "Warning - the script is known broken on gentoo. Use the docker script build_bootstack_docker.sh instead"

COREBOOT_FORK="https://gitlab.com/switchroot/bootstack/switch-coreboot"
COREBOOT_BRANCH="switch-linux"

CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"
BUILD_DIR="$PROJ_DIR"/coreboot-build
mkdir -p "$BUILD_DIR"

####### Download coreboot
if [ -d "$BUILD_DIR"/coreboot ]; then
	echo "-------- Use existing $BUILD_DIR/coreboot"
	cd "$BUILD_DIR"/coreboot
	git checkout -b "$COREBOOT_BRANCH" origin/"$COREBOOT_BRANCH" >/dev/null
	git checkout "$COREBOOT_BRANCH"
	git pull --recurse-submodules
	git submodule update --init --recursive
else
	echo "-------- Check out $COREBOOT_FORK"
	git clone --recurse-submodules -b "$COREBOOT_BRANCH" "$COREBOOT_FORK" "$BUILD_DIR"/coreboot
	cd "$BUILD_DIR"/coreboot
fi

exit 0

####### Build crossgcc-aarch64
echo "-------- Build up crossgcc-aarch64"
echo "-------- NOTE: Ignore the next warning about missed gnat!!"
make crossgcc-aarch64 CPUS=${nproc}

####### Build coreboot's cross-toolchain
echo "-------- Build up crossgcc-arm"
echo "-------- NOTE: Ignore the next warning about missed gnat!!"
make crossgcc-arm CPUS=${nproc}

####### Build coreboot's cross-toolchain
echo "-------- Build up IASL"
make iasl CPUS=${nproc}

echo "-------- Use existing $PROJ_DIR/root/usr/share/u-boot/u-boot.elf"
mkdir "$BUILD_DIR"/switch-uboot
cp "$PROJ_DIR"/root/usr/share/u-boot/u-boot.elf "$BUILD_DIR"/switch-uboot/u-boot.elf

####### Set default config and prepare for build
echo "-------- Set default config and prepare"
make nintendo_switch_defconfig

echo "-------- Make it"
make all CPUS=${nproc}
cp build/coreboot.rom "$PROJ_DIR"/distfiles/coreboot-"$(date +"%Y%m%d")".rom
