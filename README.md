# Install build environment
- Download and install this package with submodules

- Build qemu toolchain following https://wiki.gentoo.org/wiki/Embedded_Handbook/General/Compiling_with_qemu_user_chroot and using QEMU_USER_TARGETS="aarch64"

- Build cross toolchain using `crossdev -S -t aarch64-unknown-linux-gnu`

- unpack stage from http://distfiles.gentoo.org/experimental/arm64 (or the switch one from bell07) to `./root/`
- Copy switch specific configuration `cp -av target/* root/`
- create `./packages/` dir (your own binhost)

# Use the toolchain
call `qemu-chroot.sh` to enter the qemu build chroot
