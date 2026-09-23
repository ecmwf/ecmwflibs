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
# /usr/local/bin (an internal pipx install). A bare `auditwheel` on PATH
# resolves to that one, so install our own into $pybin's own site-packages
# and invoke it explicitly via -m instead.
$pybin -m pip install --quiet --upgrade auditwheel

# auditwheel's --plat/$AUDITWHEEL_PLAT choices are always restricted to
# policies for auditwheel's *own* auto-detected host architecture
# (auditwheel.architecture.Architecture.detect(), which just reads
# platform.machine(), i.e. this container's kernel/uname -- x86_64, even
# though we're cross-compiling) -- so the dockcross image's baked-in
# AUDITWHEEL_PLAT=manylinux*_aarch64 always gets rejected as an "invalid
# choice", no matter which auditwheel is installed. Passing --plat=auto on
# the command line does NOT fix this: auditwheel's argparse validates
# $AUDITWHEEL_PLAT against those choices inside the *argument definition*
# itself (EnvironmentDefault.__init__, invoked while building the parser),
# which blows up before a single command-line argument is even looked at.
# The env var itself has to be overridden. When repairing, auditwheel
# separately determines the *wheel's own* architecture straight from the ELF
# machine type of the .so's inside it, so plain "auto" mode still repairs the
# wheel correctly for its actual (aarch64) contents.
if [[ "$CC" == aarch64* && "$(uname -m)" != aarch64* ]]
then
    export AUDITWHEEL_PLAT=auto
fi

# distutils names a compiled extension module after $pybin's *own*
# sysconfig (EXT_SUFFIX), e.g. "_ecmwflibs.cpython-310-x86_64-linux-gnu.so"
# -- even when $CC (honored via the CC/CXX env vars) is the aarch64 cross
# compiler and the object code inside is genuinely aarch64. A real aarch64
# CPython's import system looks for a file matching *its own* EXT_SUFFIX
# (...-aarch64-linux-gnu.so), doesn't find it, and reports the submodule as
# entirely missing (ModuleNotFoundError, not an ELF-format error). The
# compiled code itself is already correct for aarch64 -- only the filename
# is wrong -- so build first, patch the filename in place, then package
# with --skip-build so setup.py doesn't rebuild (and re-mis-name) it.
build_wheel() {
    if [[ "$CC" == aarch64* && "$(uname -m)" != aarch64* ]]
    then
        $pybin setup.py build
        find build -name '*-x86_64-linux-gnu.so' -print0 |
            while IFS= read -r -d '' f
            do
                mv "$f" "${f/x86_64-linux-gnu/aarch64-linux-gnu}"
            done
        $pybin setup.py bdist_wheel --skip-build $plat_name_opt
    else
        $pybin setup.py bdist_wheel
    fi
}

rm -fr dist wheelhouse
build_wheel

# Do it twice to get the list of libraries

$pybin -m auditwheel repair dist/*.whl
unzip -l wheelhouse/*.whl | grep 'ecmwflibs.libs/' > libs
pip3 install -r tools/requirements.txt

python3 ./tools/copy-licences.py libs

rm -fr dist wheelhouse
build_wheel
$pybin -m auditwheel repair dist/*.whl
rm -fr dist
