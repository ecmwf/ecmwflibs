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

LD_LIBRARY_PATH=$TOPDIR/install/lib:$TOPDIR/install/lib64:$LD_LIBRARY_PATH

rm -fr dist wheelhouse
$pybin setup.py bdist_wheel

# Do it twice to get the list of libraries

auditwheel repair dist/*.whl
unzip -l wheelhouse/*.whl | grep 'ecmwflibs.libs/' > libs
pip3 install -r tools/requirements.txt

python3 ./tools/copy-licences.py libs

rm -fr dist wheelhouse
$pybin setup.py bdist_wheel
auditwheel repair dist/*.whl
rm -fr dist
