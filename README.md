# Install build environment

- Build qemu toolchain following https://wiki.gentoo.org/wiki/Embedded_Handbook/General/Compiling_with_qemu_user_chroot and using QEMU_USER_TARGETS="aarch64"
- Build cross toolchain using `crossdev -S -t aarch64-unknown-linux-gnu`
- Build distcc host following https://wiki.gentoo.org/wiki/Distcc
- Download and install this package with submodules

## Prepare the emulated compiling environment
- unpack stage from http://distfiles.gentoo.org/experimental/arm64 (or the switch one from bell07) to `./root/`
- Call the `./target-cfg/01_setup_buildhost.sh`

# Use the toolchain
## Cross compiling
call `qemu-chroot.sh` to enter the qemu build chroot
`env-update && source /etc/profile` for the first time
`emerge sys-devel/distcc` for faster future compiling (pre-configured)
emerge things you need
Copy the `./packages` folder to your web server for binhost

## build the system stage
Be sure you have all system packages in binhost. Of not, recompile them using cross-compiling above
call the `./target-cfg/02_build_stage.sh`
You find an `switch-gentoo-stage4.tar.gz` file and extracted the `stage4` in `./out/` directory
