# syntax=docker/dockerfile:1

FROM gentoo/stage3:latest AS root

# Copy crossdev configuration including switch linux headers ebuild
ADD . /tmp/context

# Download and prepare portage
RUN <<-EOF
    set -e

    emerge-webrsync

    echo "Update Ebuilds with NSW versions"
    rm -Rf /var/db/repos/gentoo/sys-kernel/linux-headers/
    cp -av /tmp/context/linux-headers/. \
           /var/db/repos/gentoo/sys-kernel/linux-headers/

    rm -Rf /var/db/repos/gentoo/sys-libs/glibc/
    cp -av /tmp/context/glibc/. /var/db/repos/gentoo/sys-libs/glibc/

    find /var/db/repos/gentoo/sys-kernel/linux-headers/ \
         /var/db/repos/gentoo/sys-libs/glibc/ \
         -type f -name '*.ebuild' -exec ebuild {} manifest \;

    cp -av /tmp/context/cross-distcc-files/* /

    tar --use-compress-program=zstd -cf /portage.tar.zst /var/db/repos/gentoo

    rm -Rf /tmp/* /var/cache/* /var/tmp* /var/log* /var/db/repos/gentoo/*
EOF


# Install crossdev and distcc
RUN <<-EOF
    set -e
    tar --use-compress-program=unzstd -xf /portage.tar.zst -C /

    # Configure portage
    env-update
    eselect profile set default/linux/amd64/23.0
    getuto

    emerge -j --getbinpkg sys-devel/crossdev sys-devel/distcc \
           llvm-core/clang:19 llvm-core/clang:20
    rm -Rf /tmp/* /var/cache/* /var/tmp* /var/log* /var/db/repos/gentoo/*
EOF


# Build the cross-toolchain
RUN <<-EOF
    set -e
    tar --use-compress-program=unzstd -xf /portage.tar.zst -C /

    crossdev --show-fail-log -S --kernel 9999.512 --libc 2.41-r5 \
            -t aarch64-unknown-linux-gnu

    # Fix clang distcc symlinks
    /fix-clang-distcc.sh

    rm -Rf /tmp/* /var/cache/* /var/tmp* /var/log* /var/db/repos/gentoo/*
    rm /portage.tar.zst
EOF

# Prepare toolchain to be used with cross-emerge.sh wrapper
RUN <<-EOF
   set -e

    # Adjust selected profile in /usr/aarch64-unknown-linux-gnu
    rm /usr/aarch64-unknown-linux-gnu/etc/portage/make.profile
    ln -s /var/db/repos/gentoo/profiles/default/linux/arm64/23.0/split-usr \
       /usr/aarch64-unknown-linux-gnu/etc/portage/make.profile

    sed -i 's:ACCEPT_KEYWORDS=.*:ACCEPT_KEYWORDS="${ARCH}":g' /usr/aarch64-unknown-linux-gnu/etc/portage/make.conf

    ## Allow override crossdev files by emerge corresponding packages
    #echo 'COLLISION_IGNORE="/usr/include"' \
    #   >> /usr/aarch64-unknown-linux-gnu/etc/portage/make.conf
EOF

EXPOSE 3632 3633

ENTRYPOINT ["/usr/bin/distccd", "--daemon", "--no-detach", "-N", "15", \
   "--log-stderr", "--stats", "--allow-private" ]
