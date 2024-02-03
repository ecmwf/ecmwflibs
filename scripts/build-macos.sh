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

# HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
HOMEBREW_NO_INSTALL_CLEANUP=1

arch=$(arch)
[[ $arch == "i386" ]] && arch="x86_64" # GitHub Actions on macOS declare i386

ARCH="arch -$arch"

source scripts/common.sh

brew_home=$(brew config | grep HOMEBREW_PREFIX | sed 's/.* //')

$ARCH brew install cmake ninja pkg-config automake

# brew cat cairo

# We don't want a dependency on X11
brew cat cairo | sed '
s/xcb=enabled/xcb=disabled/
s/xlib=enabled/xlib=disabled/
s/enable-tee/disable-tee/
s/enable-xcb/disable-xcb/
s/enable-xlib/disable-xlib/
s/enable-xlib-xrender/disable-xlib-xrender/
s/enable-quartz-image/disable-quartz-image/' > cairo.rb

cat cairo.rb

$ARCH brew install pango
$ARCH brew install netcdf
$ARCH brew install proj
$ARCH brew install libaec


$ARCH brew reinstall --build-from-source --formula cairo.rb


for p in  netcdf proj pango cairo
do
    v=$(brew info $p | grep Cellar | awk '{print $1;}' | awk -F/ '{print $NF;}')
    echo "brew $p $v" >> versions
done

# Build eccodes

cd $TOPDIR/build-ecmwf/eccodes

# We disable JASPER because of a linking issue. JPEG support comes from
# other librarues
$ARCH $TOPDIR/src/ecbuild/bin/ecbuild \
    $TOPDIR/src/eccodes \
    -GNinja \
    -DCMAKE_OSX_ARCHITECTURES=$arch \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_PYTHON=0 \
    -DENABLE_FORTRAN=0 \
    -DENABLE_BUILD_TOOLS=0 \
    -DENABLE_JPG_LIBJASPER=0 \
    -DENABLE_MEMFS=1 \
    -DENABLE_INSTALL_ECCODES_DEFINITIONS=0 \
    -DENABLE_INSTALL_ECCODES_SAMPLES=0 \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install \
    -DCMAKE_INSTALL_RPATH=$TOPDIR/install/lib $ECCODES_EXTRA_CMAKE_OPTIONS

cd $TOPDIR
$ARCH cmake --build build-ecmwf/eccodes --target install

# Build magics

cd $TOPDIR/build-ecmwf/magics
$ARCH $TOPDIR/src/ecbuild/bin/ecbuild \
    $TOPDIR/src/magics \
    -GNinja \
    -DCMAKE_OSX_ARCHITECTURES=$arch \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_PYTHON=0 \
    -DENABLE_FORTRAN=0 \
    -DENABLE_BUILD_TOOLS=0 \
    -Deccodes_DIR=$TOPDIR/install/lib/cmake/eccodes \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install \
    -DCMAKE_INSTALL_RPATH=$TOPDIR/install/lib

cd $TOPDIR
$ARCH cmake --build build-ecmwf/magics --target install

# Create wheel
rm -fr dist wheelhouse ecmwflibs/share
mkdir -p install/share/magics
cp -r install/share ecmwflibs/
cp -r $brew_home/Cellar/proj/*/share ecmwflibs/
rm -fr ecmwflibs/share/proj/*.tif
rm -fr ecmwflibs/share/proj/*.txt
rm -fr ecmwflibs/share/proj/*.pol
rm -fr ecmwflibs/share/magics/efas

# echo "================================================================================"
# for n in install/lib/*.dylib
# do
#     echo $n
#     ./scripts/libs-macos.py $n
# done
# echo "================================================================================"

strip -S install/lib/*.dylib

./scripts/versions.sh > ecmwflibs/versions.txt
