#!/usr/bin/env bash
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

set -eaux

arch=$(arch)
[[ $arch == "i386" ]] && arch="x86_64" # GitHub Actions on macOS declare i386

ARCH="arch -$arch"

diet() {

    if [[ $arch == "x86_64" ]]; then
        return
    fi

    # Remove the architectures we don't need

    echo =================================================================

    cd dist
    name=$(ls -1 *.whl)
    echo $name
    unzip *.whl
    ls -l
    cd ecmwflibs
    ls -l
    so=$(ls -1 *.so)
    echo "$so"

    lipo -thin $arch $so -output $so.$arch
    mv $so.$arch $so
    lipo -info $so
    cd ..
    zip -r $name ecmwflibs
    cd ..

    echo =================================================================

}

# version=$(echo $1| sed 's/\.//')

pip3 install wheel delocate setuptools

rm -fr dist wheelhouse tmp
$ARCH python3 setup.py bdist_wheel
diet

# Do it twice to get the list of libraries

$ARCH delocate-wheel -w wheelhouse dist/*.whl
unzip -l wheelhouse/*.whl | grep 'dylib' >libs
pip3 install -r tools/requirements.txt
python3 ./tools/copy-licences.py libs

name=$(ls -1 wheelhouse/*.whl)
echo $name

rm -fr dist wheelhouse
$ARCH python3 setup.py bdist_wheel # --plat-name $arch
diet

newname=$(ls -1 wheelhouse/*.whl | sed "s/-universal2/-${arch}-/")
mv $name $newname
$ARCH delocate-wheel -w wheelhouse dist/*.whl
