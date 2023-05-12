#!/usr/bin/env bash
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

set -eaux

platform=$(uname)
arch=$(uname -a | sed 's/.* //')

if [[ "$platform.$arch" != "Darwin.arm64" ]]
then
    exit 1
fi

here=$(dirname $0)
cd $here/..

rm -fr build* dist install wheelhouse cairo.rb

./scripts/build-macos.sh

mkdir -p /tmp/build-macos-m1
PATH=/tmp/build-macos-m1:$PATH

for n in 11 10 9 8
do
    rm -fr wheelhouse
    brew install python@3.$n


    ln -sf $(ls -1d /opt/homebrew/Cellar/python@3.$n/*/bin/python3.$n) /tmp/build-macos-m1/python3
    ln -sf $(ls -1d /opt/homebrew/Cellar/python@3.$n/*/bin/python3.$n) /tmp/build-macos-m1/python
    ln -sf $(ls -1d /opt/homebrew/Cellar/python@3.$n/*/bin/pip3.$n) /tmp/build-macos-m1/pip3
    ln -sf $(ls -1d /opt/homebrew/Cellar/python@3.$n/*/bin/pip3.$n) /tmp/build-macos-m1/pip

    ./scripts/wheel-macos.sh
    pip3 install twine
    twine upload wheelhouse/*.whl

done
