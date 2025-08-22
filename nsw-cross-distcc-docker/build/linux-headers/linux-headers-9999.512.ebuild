# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ETYPE="headers"
H_SUPPORTEDARCH="arm64"

inherit kernel-2 git-r3

KEYWORDS="-* arm64"
HOMEPAGE="https://github.com/CTCaer/switch-l4t-kernel-4.9"

# bug #816762
RESTRICT="test"

EXTRAVERSION="-l4t-gentoo"

DESCRIPTION="Nintendo Switch kernel Headers"

src_unpack() {
	EGIT_REPO_URI="https://github.com/CTCaer/switch-l4t-kernel-4.9"
	EGIT_BRANCH=""
	EGIT_TAG="linux-5.1.2"
	EGIT_CHECKOUT_DIR="${S}"
	git-r3_src_unpack
	rm -Rf "${S}"/.git*

	EGIT_REPO_URI="https://github.com/CTCaer/switch-l4t-kernel-nvidia"
	EGIT_BRANCH=""
	EGIT_TAG="linux-5.1.2"
	EGIT_CHECKOUT_DIR="${S}/nvidia"
	git-r3_src_unpack
	rm -Rf "${EGIT_CHECKOUT_DIR}"/.git*

	EGIT_REPO_URI="https://gitlab.com/switchroot/kernel/l4t-kernel-nvgpu/"
	EGIT_BRANCH="linux-3.4.0-r32.5"
	EGIT_TAG=""
	EGIT_CHECKOUT_DIR="${S}/nvidia/nvgpu"
	git-r3_src_unpack
	rm -Rf "${EGIT_CHECKOUT_DIR}"/.git*

	EGIT_REPO_URI="https://github.com/CTCaer/switch-l4t-platform-t210-nx"
	EGIT_BRANCH=""
	EGIT_TAG="linux-5.1.2"
	EGIT_CHECKOUT_DIR="${S}/nvidia/platform/t210/nx"
	git-r3_src_unpack
	rm -Rf "${EGIT_CHECKOUT_DIR}"/.git*

	EGIT_REPO_URI="https://gitlab.com/switchroot/kernel/l4t-soc-tegra"
	EGIT_BRANCH="l4t/l4t-r32.5"
	EGIT_TAG=""
	EGIT_CHECKOUT_DIR="${S}/nvidia/soc/tegra"
	git-r3_src_unpack
	rm -Rf "${EGIT_CHECKOUT_DIR}"/.git*

	EGIT_REPO_URI="https://gitlab.com/switchroot/kernel/l4t-soc-t210"
	EGIT_BRANCH="l4t/l4t-r32.5"
	EGIT_TAG=""
	EGIT_CHECKOUT_DIR="${S}/nvidia/soc/t210/"
	git-r3_src_unpack
	rm -Rf "${EGIT_CHECKOUT_DIR}"/.git*

	EGIT_REPO_URI="https://gitlab.com/switchroot/kernel/l4t-platform-tegra-common"
	EGIT_BRANCH="l4t/l4t-r32.5"
	EGIT_TAG=""
	EGIT_CHECKOUT_DIR="${S}/nvidia/platform/tegra/common/"
	git-r3_src_unpack
	rm -Rf "${EGIT_CHECKOUT_DIR}"/.git*

	EGIT_REPO_URI="https://gitlab.com/switchroot/kernel/l4t-platform-t210-common"
	EGIT_BRANCH="l4t/l4t-r32.5"
	EGIT_TAG=""
	EGIT_CHECKOUT_DIR="${S}/nvidia/platform/t210/common/"
	git-r3_src_unpack
	rm -Rf "${EGIT_CHECKOUT_DIR}"/.git*
}

src_prepare() {
	eapply "${FILESDIR}"/01-unify_l4t_sources.patch
	eapply "${FILESDIR}"/02-gcc-12-4.9.140.511.patch
	eapply "${FILESDIR}"/03-nvidia_drivers_actmon_add__init_annotation_to_tegra_actmon_register.patch
	eapply "${FILESDIR}"/04-nvidia_drivers_eventlib_use_existing_kernel_sync_bitops.patch
	eapply "${FILESDIR}"/05_irq_gic_drop__init_annotation_from_gic_init_fiq.patch
	eapply "${FILESDIR}"/06-add_wan_hdlc_x25.patch
	eapply_user
	default
}

#This is skipped..... do to restrict="test"
src_test() {
    einfo "Possible unescaped attribute/type usage"
    egrep -r \
        -e '(^|[[:space:](])(asm|volatile|inline)[[:space:](]' \
        -e '\<([us](8|16|32|64))\>' \
        .

    emake ARCH="$(tc-arch-kernel)" headers_check
}

src_install() {
	kernel-2_src_install

	find "${ED}" \( -name '.install' -o -name '*.cmd' \) -delete || die
	# Delete empty directories
	find "${ED}" -empty -type d -delete || die
}
