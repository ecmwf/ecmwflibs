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

TOPDIR=$(/bin/pwd)

LD_LIBRARY_PATH=$TOPDIR/install/lib:$TOPDIR/install/lib64:$LD_LIBRARY_PATH
if [[ -d /opt/python/cp${version}-cp${version}*/bin ]]
then
    PATH=/opt/python/cp${version}-cp${version}*/bin:$PATH
fi

rm -fr dist wheelhouse
python3 setup.py bdist_wheel

# Do it twice to get the libraries
auditwheel repair dist/*.whl
unzip -l wheelhouse/*.whl | grep 'ecmwflibs.libs/' | sed 's,.*ecmwflibs.libs/,,' > libs
pip3 install -r tools/requirements.txt
python3 ./tools/copy-licences.py libs

rm -fr dist wheelhouse
python3 setup.py bdist_wheel
auditwheel repair dist/*.whl
rm -fr dist
