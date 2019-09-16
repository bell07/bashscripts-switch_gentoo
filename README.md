# My bash scripts for gentoo on Nintendo switch
This is my script collection for cross-complle Gentoo Linux for Nintendo Switch. I build my own binhost packages, stage and release tarballs, using this scripts. You can compile your own stages and releases and binhost ;-)

More informations in the [Switch Gentoo Wiki](https://github.com/bell07/bashscripts-switch_gentoo/wiki)

# Install build environment
- Build qemu toolchain following https://wiki.gentoo.org/wiki/Embedded_Handbook/General/Compiling_with_qemu_user_chroot and using QEMU_USER_TARGETS="aarch64"
- Build cross toolchain using `crossdev -S --gcc 7.3.0-r6 -t aarch64-unknown-linux-gnu`
- Build distcc host following https://wiki.gentoo.org/wiki/Distcc; set --allow 127.0.0.1 to allow qemu-chroot to use the crossdev compiler
- Download and install this package with all submodules
  `git clone --recurse-submodules https://github.com/bell07/bashscripts-switch_gentoo`

## Prepare the emulated compiling environment
- unpack stage [switch-gentoo-release.tar.gz](https://bell.7u.org/pub/gentoo-switch/) to `./root/`
- Call the `./buildscripts/update_buildhost.sh`

Second way is
- Call `./buildscripts/build_release.sh`  to build own release build from binhost packages
- Copy `./out/release/` dir to `./root/`
- Call the `./buildscripts/update_buildhost.sh`

# Use the toolchain / compile own binhost
## Cross compiling
- call `./qemu-chroot.sh` to enter the qemu build chroot
- emerge things you need
- (optional) all packages covered by bell07's binhost can be installed by `FEATURES="-getbinpkg" emerge app-portage/nintendo-switch-buildhost-meta`
- by default the FEATURES="-getbinpkg" is set in buildhost root so binary packages are rebuilt by default
- Copy the `./packages` folder to your web server for binhost

## build the Release
- call the `./buildscripts/build_release.sh`
- You find `switch-gentoo-release-$date.tar.gz` and `switch-gentoo-boot-$date.zip` files in `./out/` directory

## build the coreboot.rom
HINT: Just use the precompiled coreboot.rom from sys-boot/nintendo-switch-coreboot-bin package.
INFO: Self-compiling works on PC only and requires a lot of non-gentoo dependencies.
WARNING: This Build script is incomplete, so created coreboot.rom does have less features.

- build sys-boot/nintendo-switch-u-boot in buildhost or place u-boot.elf to coreboot-build/u-boot.elf
- call `./buildscripts/build_coreboot.sh`
- Get caffee and wait
- You find coreboot.rom in `./out/` directory
