# Install build environment
1. Follow https://wiki.gentoo.org/wiki/Embedded_Handbook/General/Compiling_with_qemu_user_chroot using QEMU_USER_TARGETS="aarch64"

2. unpack stage from http://distfiles.gentoo.org/experimental/arm64 to `./root/`
3. create `./packages/` dir (your own binhost)

3. Install https://github.com/bell07/bashscripts-system_chroot beside this repo into `../system-chroot/`

3. call `qemu-chroot.sh` to enter the build chroot
