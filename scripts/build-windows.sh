#!/usr/bin/env bash
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

set -eaux

source scripts/common.sh

here=$(pwd)
cd $VCPKG_INSTALLATION_ROOT
url=$(git remote -v | head -1 | awk '{print $2;}')
# git checkout 2021.05.12
sha1=$(git rev-parse HEAD)
cd $here

echo git $url $sha1 > versions

# the results of the following suggested that pkg-config.exe is not installed on the latest
# Windows runner
#find /c/ -name pkg-config.exe
#exit 1

# if [[ $WINARCH == "x64" ]]; then
#     PKG_CONFIG_EXECUTABLE=/c/rtools43/mingw64/bin/pkg-config.exe
# else
#     PKG_CONFIG_EXECUTABLE=/c/rtools43/mingw32/bin/pkg-config.exe
# fi

vcpkg install pkgconf

for p in expat netcdf-c[core,netcdf-4,hdf5] pango sqlite3[core,tool] libpng
do
    vcpkg install $p:$WINARCH-windows
    n=$(echo $p | sed 's/\[.*//')
    v=$(vcpkg list $n | awk '{print $2;}')
    echo "vcpkg $n $v" >> versions
done

echo =================================================================
find $VCPKG_INSTALLATION_ROOT -type f -name png.h -print
echo =================================================================


pip install ninja wheel dll-diagnostics

echo "pip $(pip freeze | grep dll-diagnostics | sed 's/==/ /')" >> versions

# Build libaec
git clone $GIT_AEC src/aec
cd src/aec
git checkout $AEC_VERSION
cd $TOPDIR
mkdir -p build-other/aec
cd build-other/aec

cmake  \
    $TOPDIR/src/aec -G"NMake Makefiles" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install \
    -DCMAKE_TOOLCHAIN_FILE=/c/vcpkg/scripts/buildsystems/vcpkg.cmake \
    -DCMAKE_C_COMPILER=cl.exe

cd $TOPDIR
cmake --build build-other/aec --target install


# Build proj

git clone $GIT_PROJ src/proj
cd src/proj
git checkout $PROJ_VERSION
cd $TOPDIR

mkdir -p build-other/proj
cd build-other/proj

cmake  \
    $TOPDIR/src/proj -G"NMake Makefiles" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_TIFF=0 \
    -DENABLE_CURL=0 \
    -DBUILD_TESTING=0 \
    -DBUILD_PROJSYNC=0 \
    -DSQLITE3_BIN_PATH=C:/vcpkg/packages/sqlite3_${WINARCH}-windows/tools/sqlite3.exe \
    -DBUILD_SHARED_LIBS=1 \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install \
    -DCMAKE_TOOLCHAIN_FILE=/c/vcpkg/scripts/buildsystems/vcpkg.cmake \
    -DCMAKE_C_COMPILER=cl.exe

cd $TOPDIR
cmake --build build-other/proj --target install

# Build eccodes

cd $TOPDIR/build-ecmwf/eccodes

$TOPDIR/src/ecbuild/bin/ecbuild \
    $TOPDIR/src/eccodes \
    -G"NMake Makefiles" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_PYTHON=0 \
    -DENABLE_FORTRAN=0 \
    -DENABLE_BUILD_TOOLS=0 \
    -DENABLE_MEMFS=1 \
    -DENABLE_INSTALL_ECCODES_DEFINITIONS=0 \
    -DENABLE_INSTALL_ECCODES_SAMPLES=0 \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install \
    -DCMAKE_TOOLCHAIN_FILE=/c/vcpkg/scripts/buildsystems/vcpkg.cmake \
    -DCMAKE_C_COMPILER=cl.exe $ECCODES_EXTRA_CMAKE_OPTIONS 

    # -DPKG_CONFIG_EXECUTABLE=$PKG_CONFIG_EXECUTABLE

cd $TOPDIR
cmake --build build-ecmwf/eccodes --target install

# Build magics

# -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON
#

cd $TOPDIR/build-ecmwf/magics
$TOPDIR/src/ecbuild/bin/ecbuild \
    $TOPDIR/src/magics \
    -G"NMake Makefiles" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_PYTHON=0 \
    -DENABLE_FORTRAN=0 \
    -DENABLE_BUILD_TOOLS=0 \
    -Deccodes_DIR=$TOPDIR/install/lib/cmake/eccodes \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install \
    -DCMAKE_TOOLCHAIN_FILE=/c/vcpkg/scripts/buildsystems/vcpkg.cmake \
    -DCMAKE_C_COMPILER=cl.exe

    # -DPKG_CONFIG_EXECUTABLE=$PKG_CONFIG_EXECUTABLE


cd $TOPDIR
cmake --build build-ecmwf/magics --target install

# Create wheel

rm -fr dist wheelhouse ecmwflibs/share
cp -r install/share ecmwflibs/
rm -fr ecmwflibs/share/magics/efas
mkdir -p ecmwflibs/share/proj
python tools/copy-dlls.py install/bin/MagPlus.dll ecmwflibs/
pip install -r tools/requirements.txt
find ecmwflibs -name '*.dll' > libs
python ./tools/copy-licences.py libs

mkdir -p install/include

./scripts/versions.sh > ecmwflibs/versions.txt
