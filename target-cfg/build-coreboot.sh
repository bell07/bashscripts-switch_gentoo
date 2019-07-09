#!/bin/bash

COREBOOT_FORK="https://github.com/fail0verflow/switch-coreboot"
SHOFEL2_FORK="https://github.com/fail0verflow/shofel2/"

CFG_DIR="$(realpath "$(dirname $0)")"
PROJ_DIR="$(dirname "$CFG_DIR")"
BUILD_DIR="$PROJ_DIR"/coreboot-build
mkdir -p "$BUILD_DIR"

####### Download coreboot
if [ -d "$BUILD_DIR"/coreboot ]; then
	echo "-------- Use existing $BUILD_DIR/coreboot"
else
	echo "-------- Check out $COREBOOT_FORK"
	git clone "$COREBOOT_FORK" "$BUILD_DIR"/coreboot
fi

cd "$BUILD_DIR"/coreboot

####### Build crossgcc-aarch64
if [ -f util/crossgcc/xgcc/.aarch64-elf-GCC.*.success ]; then
	echo "-------- Use existing crossgcc-aarch64"
else
	echo "-------- Build up crossgcc-aarch64"
	echo "-------- NOTE: Ignore the next warning about missed gnat!!"
	make crossgcc-aarch64 CPUS=${nproc}
fi

####### Build coreboot's cross-toolchain
if [ -f util/crossgcc/xgcc/.arm-eabi-GCC.*.success ]; then
	echo "-------- Use existing crossgcc-arm"
else
	echo "-------- Build up crossgcc-arm"
	echo "-------- NOTE: Ignore the next warning about missed gnat!!"
	make crossgcc-arm CPUS=${nproc}
fi


####### Build coreboot's cross-toolchain
if [ -f util/crossgcc/xgcc/.IASL.*.success ]; then
	echo "-------- Use existing IASL"
else
	echo "-------- Build up IASL"
	make iasl CPUS=${nproc}
fi

####### Get Shofel2
if [ -d "$BUILD_DIR"/shofel2 ]; then
	echo "-------- Use existing $BUILD_DIR/shofel2"
else
	echo "-------- Check out $SHOFEL2_FORK"
	git clone "$SHOFEL2_FORK" "$BUILD_DIR"/shofel2
fi

####### Get tegra_mtc.bin
if [ -f "$BUILD_DIR"/tegra_mtc.bin ]; then
	echo "-------- Use existing $BUILD_DIR/tegra_mtc.bin"
else
	echo "-------- build cbfstool to get tegra_mtc.bin extracted"
	make util CPUS=${nproc}

	cd "$BUILD_DIR"/coreboot/util/cbfstool
	make CPUS=${nproc}

	echo "-------- download and extract tegra_mtc.bin"
	cd "$BUILD_DIR"
	rm ryu-mxb48j-factory-ce6d5a7b.zip* 2> /dev/null
	wget https://dl.google.com/dl/android/aosp/ryu-mxb48j-factory-ce6d5a7b.zip
	unzip ryu-mxb48j-factory-ce6d5a7b.zip ryu-mxb48j/bootloader-dragon-google_smaug.7132.260.0.img
	rm ryu-mxb48j-factory-ce6d5a7b.zip
	coreboot/util/cbfstool/cbfstool ryu-mxb48j/bootloader-dragon-google_smaug.7132.260.0.img extract -n fallback/tegra_mtc -f tegra_mtc.bin
	rm -Rf ryu-mxb48j
	cd "$BUILD_DIR"/coreboot
fi
cp "$BUILD_DIR"/tegra_mtc.bin "$BUILD_DIR"/coreboot/

if [ -f "$BUILD_DIR"/u-boot.elf ]; then
	echo "-------- Use existing $BUILD_DIR/u-boot.elf"
else
	if [ -f "$PROJ_DIR"/root/boot/u-boot.elf ]; then
		echo "-------- Use existing $PROJ_DIR/root/boot/u-boot.elf"
		cp "$PROJ_DIR"/root/boot/u-boot.elf "$BUILD_DIR"/u-boot.elf
	else
		echo "-------- No u-boot.elf found, exit"
		exit 1
	fi
fi

####### Set default config and prepare for build
echo "-------- Set default config and prepare"
cp configs/nintendo_switch_defconfig .config
cat >> .config << EOF
CONFIG_MTC_FILE=\"../tegra_mtc.bin\"
CONFIG_MTC_TABLES_DIRECTORY=\"../shofel2/mtc_tables\"
CONFIG_PAYLOAD_FILE=\"../u-boot.elf\"
EOF
make olddefconfig 2>/dev/null


echo "-------- Make it"
make all CPUS=${nproc}

echo "-------- Copy build/coreboot.rom to $PROJ_DIR/out"
mkdir -p "$PROJ_DIR"/out/
cp -v build/coreboot.rom "$PROJ_DIR"/out/
