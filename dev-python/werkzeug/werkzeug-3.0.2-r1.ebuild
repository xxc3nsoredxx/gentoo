# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=flit
PYTHON_COMPAT=( python3_{10..12} pypy3 )

inherit distutils-r1

DESCRIPTION="Collection of various utilities for WSGI applications"
HOMEPAGE="
	https://palletsprojects.com/p/werkzeug/
	https://pypi.org/project/Werkzeug/
	https://github.com/pallets/werkzeug/
"
SRC_URI="
	https://github.com/pallets/werkzeug/archive/${PV}.tar.gz
		-> ${P}.gh.tar.gz
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="test-rust"

RDEPEND="
	>=dev-python/markupsafe-2.1.1[${PYTHON_USEDEP}]
"
# NOTE: remove the loong mask after greenlet gains support for loong
# see https://github.com/python-greenlet/greenlet/pull/257
BDEPEND="
	test? (
		dev-python/ephemeral-port-reserve[${PYTHON_USEDEP}]
		dev-python/pytest-timeout[${PYTHON_USEDEP}]
		>=dev-python/pytest-xprocess-1[${PYTHON_USEDEP}]
		>=dev-python/watchdog-2.3[${PYTHON_USEDEP}]
		test-rust? (
			dev-python/cryptography[${PYTHON_USEDEP}]
		)
		!hppa? ( !ia64? ( !loong? (
			$(python_gen_cond_dep '
				dev-python/greenlet[${PYTHON_USEDEP}]
			' python3_{10..11})
		) ) )
	)
"

distutils_enable_tests pytest

PATCHES=(
	# https://github.com/pallets/werkzeug/issues/2875
	"${FILESDIR}/${PN}-3.0.2-pytest-xprocess-1.patch"
)

python_test() {
	local EPYTEST_DESELECT=(
		# RequestRedirect class started incidentally being tested
		# with pytest-8, though the test isn't prepared for that
		# https://github.com/pallets/werkzeug/issues/2845
		'tests/test_exceptions.py::test_response_body[RequestRedirect]'
	)
	if ! has_version "dev-python/cryptography[${PYTHON_USEDEP}]"; then
		EPYTEST_DESELECT+=(
			"tests/test_serving.py::test_server[https]"
			tests/test_serving.py::test_ssl_dev_cert
			tests/test_serving.py::test_ssl_object
		)
	fi

	# the default portage tempdir is too long for AF_UNIX sockets
	local -x TMPDIR=/tmp
	epytest -p no:django -p no:httpbin tests
}
