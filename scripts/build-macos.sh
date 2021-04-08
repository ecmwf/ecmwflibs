#!/usr/bin/env bash
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

set -eaux
uname -a

source scripts/common.sh

brew install cmake ninja pkg-config automake

# We don't want a dependency on X11
EDITOR=cat brew edit cairo | sed '
s/^Editing .*//
s/enable-gobject/disable-gobject/
s/enable-tee/disable-tee/
s/enable-xcb/disable-xcb/
s/enable-xlib/disable-xlib/
s/enable-xlib-xrender/disable-xlib-xrender/
s/enable-quartz-image/disable-quartz-image/' > cairo.rb

brew install --build-from-source cairo.rb

EDITOR=cat brew edit pango | sed '
s/^Editing .*//
s/introspection=enabled/introspection=disabled/' > pango.rb

brew install --build-from-source pango.rb

brew install netcdf
brew install proj

for p in  netcdf proj pango cairo
do
    v=$(brew info $p | grep Cellar | awk '{print $1;}' | awk -F/ '{print $NF;}')
    echo "brew $p $v" >> versions
done

# -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"

# Build eccodes

cd $TOPDIR/build-ecmwf/eccodes

$TOPDIR/src/ecbuild/bin/ecbuild \
    $TOPDIR/src/eccodes \
    -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_PYTHON=0 \
    -DENABLE_FORTRAN=0 \
    -DENABLE_BUILD_TOOLS=0 \
    -DENABLE_MEMFS=1 \
    -DENABLE_INSTALL_ECCODES_DEFINITIONS=0 \
    -DENABLE_INSTALL_ECCODES_SAMPLES=0 \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install \
    -DCMAKE_INSTALL_RPATH=$TOPDIR/install/lib

cd $TOPDIR
cmake --build build-ecmwf/eccodes --target install

# Build magics

cd $TOPDIR/build-ecmwf/magics
$TOPDIR/src/ecbuild/bin/ecbuild \
    $TOPDIR/src/magics \
    -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_PYTHON=0 \
    -DENABLE_FORTRAN=0 \
    -DENABLE_BUILD_TOOLS=0 \
    -Deccodes_DIR=$TOPDIR/install/lib/cmake/eccodes \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install \
    -DCMAKE_INSTALL_RPATH=$TOPDIR/install/lib

cd $TOPDIR
cmake --build build-ecmwf/magics --target install



# Create wheel
rm -fr dist wheelhouse ecmwflibs/share
mkdir -p install/share/magics
cp -r install/share ecmwflibs/
cp -r /usr/local/Cellar/proj/*/share ecmwflibs/
strip -S install/lib/*.dylib

./scripts/versions.sh > ecmwflibs/versions.txt
