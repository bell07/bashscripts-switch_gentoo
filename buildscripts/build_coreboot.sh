#!/bin/bash

COREBOOT_FORK="https://gitlab.com/switchroot/bootstack/switch-coreboot"
COREBOOT_BRANCH="switch-proper-vpr"

CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"
BUILD_DIR="$PROJ_DIR"/coreboot-build
mkdir -p "$BUILD_DIR"

####### Download coreboot
if [ -d "$BUILD_DIR"/coreboot ]; then
	echo "-------- Use existing $BUILD_DIR/coreboot"
	git submodule update --init --recursive "$BUILD_DIR"/coreboot
else
	echo "-------- Check out $COREBOOT_FORK"
	git clone "$COREBOOT_FORK" "$BUILD_DIR"/coreboot
fi

cd "$BUILD_DIR"/coreboot
git checkout origin/"$COREBOOT_BRANCH"

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
