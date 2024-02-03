#!/usr/bin/env bash
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

set -eaux
echo $PATH
VERSION=$1

echo $GITHUB_PATH || true
cat $GITHUB_PATH || true
python3 --version
which python3
which pip3
# PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin
# unset PKG_CONFIG_PATH

# env | sort



pip3 install --upgrade pip
pip3 install wheel delocate setuptools

# https://setuptools.pypa.io/en/latest/userguide/ext_modules.html#cross-platform-compilation
# Prevent ext_modules from being built as universal
# CXX=./scripts/cxx-no-arch.sh
# CC=./scripts/c-no-arch.sh

which python3
python3 --version
which delocate-wheel

rm -fr dist wheelhouse tmp
python3 setup.py bdist_wheel

# Do it twice to get the list of libraries

delocate-wheel -w wheelhouse dist/*.whl
unzip -l wheelhouse/*.whl | grep 'dylib' >libs
pip3 install -r tools/requirements.txt
python3 ./tools/copy-licences.py libs

rm -fr dist wheelhouse
python3 setup.py bdist_wheel
delocate-wheel -w wheelhouse dist/*.whl
