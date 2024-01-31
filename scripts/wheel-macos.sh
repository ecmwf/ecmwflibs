#!/usr/bin/env bash
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

set -eaux

# version=$(echo $1| sed 's/\.//')

pip3 install wheel delocate

rm -fr dist wheelhouse tmp
python3 setup.py bdist_wheel --plat-name $(arch)

mkdir tmp
cd tmp
unzip ../dist/*.whl
find . -name '*.so' -print | xargs lipo -info
find . -name '*.so' -print | xargs otool -L
cd ..
echo =================================================================
ls -lrt dist
unzip -l dist/*.whl
echo =================================================================

file ecmwflibs/_ecmwflibs.cpython-310-darwin.so
otool -L ecmwflibs/_ecmwflibs.cpython-310-darwin.so
echo =================================================================

# Do it twice to get the list of libraries

arch -$(arch) delocate-wheel -w wheelhouse dist/*.whl
unzip -l wheelhouse/*.whl | grep 'dylib' > libs
pip3 install -r tools/requirements.txt
python3 ./tools/copy-licences.py libs

rm -fr dist wheelhouse
python3 setup.py bdist_wheel
arch -$(arch) delocate-wheel -w wheelhouse dist/*.whl
