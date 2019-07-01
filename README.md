# Install build environment

- Build qemu toolchain following https://wiki.gentoo.org/wiki/Embedded_Handbook/General/Compiling_with_qemu_user_chroot and using QEMU_USER_TARGETS="aarch64"
- Build cross toolchain using `crossdev -S -t aarch64-unknown-linux-gnu`
- Build distcc host following https://wiki.gentoo.org/wiki/Distcc; set --allow 127.0.0.1 for communication to qemu toolchain
- Download and install this package with all submodules
  `git clone --recurse-submodules https://github.com/bell07/bashscripts-switch_gentoo`

## Prepare the emulated compiling environment
- unpack stage from https://bell.7u.org/pub/gentoo-switch/switch-gentoo-stage3.tar.gz to `./root/`
- Call the `./target-cfg/update_buildhost.sh`

# Use the toolchain / compile own binhost
## Cross compiling
- call `./qemu-chroot.sh` to enter the qemu build chroot
- emerge things you need
- Copy the `./packages` folder to your web server for binhost

## build the system stage3
- Be sure you have all system packages in binhost. If not, recompile them using cross-compiling above
- call the `./target-cfg/build_stage.sh`
- You find an `switch-gentoo-stage3.tar.gz` file and extracted the `stage3` in `./out/` directory

## build the Release stage
- build stage3 if does not exists.
- call the `./target-cfg/build_release.sh`
- You find an `switch-gentoo-release.tar.gz` file and extracted the `release` in `./out/` directory
