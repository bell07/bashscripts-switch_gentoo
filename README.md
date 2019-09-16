# My bash scripts for gentoo on Nintendo switch
This is my script collection for cross-complle Gentoo Linux for Nintendo Switch. I build my own binhost packages, stage and release tarballs, using this scripts. You can compile your own stages and releases and binhost ;-)

More informations in the [Switch Gentoo Wiki](https://github.com/bell07/bashscripts-switch_gentoo/wiki)


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
