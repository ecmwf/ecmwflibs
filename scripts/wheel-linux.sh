#!/usr/bin/env bash
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

set -eaux

version=$(echo $1| sed 's/\.//')

pybin=$(ls -1d /opt/python/cp${version}-cp${version}*/bin/python3 2>/dev/null | head -1)
if [[ -z "$pybin" ]]
then
	pybin=$(ls -1d /opt/python/cp${version}t-cp${version}t*/bin/python3 2>/dev/null | head -1)
fi
if [[ -z "$pybin" ]]
then
	echo "Cannot find Python binary for cp${version} under /opt/python"
	exit 1
fi

TOPDIR=$(/bin/pwd)

export LD_LIBRARY_PATH=$TOPDIR/install/lib:$TOPDIR/install/lib64:${LD_LIBRARY_PATH:-}

# $pybin is a host-arch (x86_64) interpreter even when cross-compiling for
# aarch64 -- the /opt/python pythons here are only used to run setup.py, not
# to execute the target binaries -- so distutils' own platform detection
# tags the wheel "linux_x86_64" regardless of what the .so's were actually
# built for. Override it explicitly so auditwheel repair (which reads the
# untagged wheel's platform to check it against $AUDITWHEEL_PLAT) has the
# right starting tag to convert into e.g. manylinux2014_aarch64.
plat_name_opt=""
[[ "$CC" == aarch64* && "$(uname -m)" != aarch64* ]] && plat_name_opt="--plat-name=linux_aarch64"

# The manylinux images ship their own auditwheel preinstalled under
# /usr/local/bin (an internal pipx install, apparently predating aarch64
# support in its bundled policy -- it lists only x86_64 platform tags). A
# bare `auditwheel` on PATH resolves to that one, so install our own into
# $pybin's own site-packages and invoke it explicitly via -m instead.
$pybin -m pip install --quiet --upgrade auditwheel

rm -fr dist wheelhouse
$pybin setup.py bdist_wheel $plat_name_opt

# Do it twice to get the list of libraries

$pybin -m auditwheel repair dist/*.whl
unzip -l wheelhouse/*.whl | grep 'ecmwflibs.libs/' > libs
pip3 install -r tools/requirements.txt

python3 ./tools/copy-licences.py libs

rm -fr dist wheelhouse
$pybin setup.py bdist_wheel $plat_name_opt
$pybin -m auditwheel repair dist/*.whl
rm -fr dist
