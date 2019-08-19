# My bash scripts for gentoo on Nintendo switch
This is my script collection for cross-complle Gentoo Linux for Nintendo Switch. I build my own binhost packages, stage and release tarballs, using this scripts. You can compile your own stages and releases and binhost ;-)

# Install build environment
- Build qemu toolchain following https://wiki.gentoo.org/wiki/Embedded_Handbook/General/Compiling_with_qemu_user_chroot and using QEMU_USER_TARGETS="aarch64"
- Build cross toolchain using `crossdev -S --gcc 7.3.0-r6 -t aarch64-unknown-linux-gnu`
- Build distcc host following https://wiki.gentoo.org/wiki/Distcc; set --allow 127.0.0.1 to allow qemu-chroot to use the crossdev compiler
- Download and install this package with all submodules
  `git clone --recurse-submodules https://github.com/bell07/bashscripts-switch_gentoo`

## Prepare the emulated compiling environment
- unpack stage from [switch-gentoo-release.tar.gz](https://bell.7u.org/pub/gentoo-switch/switch-gentoo-release.tar.gz) to `./root/`
- Call the `./buildscripts/update_buildhost.sh`

# Use the toolchain / compile own binhost
## Cross compiling
- call `./qemu-chroot.sh` to enter the qemu build chroot
- emerge things you need
- (optional) all packages covered by bell07's binhost can be installed by app-portage/nintendo-switch-buildhost-meta package
- (optional) you can rebuild packages by FEATURES="-getbinpkg" emerge ....
- Copy the `./packages` folder to your web server for binhost

## build the system stage3
- Be sure you have all system packages in binhost. If not, recompile them using cross-compiling above
- call the `./buildscripts/build_stage.sh`
- You find an `switch-gentoo-stage3.tar.gz` file and extracted the `stage3` in `./out/` directory

## build the Release stage
- build stage3 if does not exists.
- call the `./buildscripts/build_release.sh`
- You find an `switch-gentoo-release.tar.gz` file and extracted the `release` in `./out/` directory

## build the coreboot.rom
HINT: Just use the precompiled coreboot.rom from sys-boot/nintendo-switch-coreboot-bin package.
INFO: Self-compiling works on PC only and requires a lot of non-gentoo dependencies.
WARNING: This Build script is incomplete, so created coreboot.rom does have less features.

- build sys-boot/nintendo-switch-u-boot in buildhost or place u-boot.elf to coreboot-build/u-boot.elf
- call `./buildscripts/build_coreboot.sh`
- Get caffee and wait
- You find coreboot.rom in `./out/` directory

# First boot
## Install
- Format SD card with 2 partitions, (mmcblk0p1) fat32 and (mmcblk0p2) ext4
- Extract the [switch-gentoo-release.tar.gz](https://bell.7u.org/pub/gentoo-switch/switch-gentoo-release.tar.gz) into ext4 partition
- Extract the [switch-gentoo-boot.zip](https://bell.7u.org/pub/gentoo-switch/switch-gentoo-boot.zip) into fat32 partition

### Install to other partition
- Adjust /etc/fstab
- Adjust /etc/nintendo-switch-boot.txt
- Update boot.scr
  - If you are able to chroot from other linux on switch, do it and update the boot.scr using installed update-boot.scr.sh script.
  - You can adjust the /etc/nintendo-switch-boot.txt and use update-boot.scr.sh on your qemu-chroot.
  - Just ask me...
- Copy the updated boot.scr for the fat32 partition /gentoo folder.

## Configure
- Mount the etx4 partition
- Set `PermitRootLogin yes`in /etc/ssh/sshd_config
  Note: password is "switch" and should be changed after first login.
  Disable the settings after you created new user
- For wifi connection, just create /etc/wpa_supplicant/wpa_supplicant.conf
```
ctrl_interface=/var/run/wpa_supplicant
ap_scan=1

network={
 ssid="Your_WIFI_SSID"
 psk="Your_WPA_Password"
}
```
Boot the switch trough hekate
- If the wpa_supplicant is set up, you can just connect over wifi
  - ssh root@nintendo-switch
- Second way is to connect trough USB
```
modprobe cdc_ncm
### Check you got new interface in `ifconfig`
ifconfig enp0s20f0u up
ifconfig enp0s20f0u2 192.168.76.7/24 up
ssh root@192.168.76.1
```

## Trobleshooting if connection fails
- Wait longer maybe your router is slow
- Mount the ext4 partition
- enable `rc_logger="YES"` in ${your_partition}/etc/rc.conf
- Set `wpa_supplicant_args="-f /var/log/wpa_supplicant.log"` in  ${your_partition}/etc/conf.d/wpa_supplicant
