#!/usr/bin/env bash
set -eaux

source scripts/common.sh

vcpkg install expat:$WINARCH-windows
vcpkg install netcdf-c:$WINARCH-windows
vcpkg install pango:$WINARCH-windows
vcpkg install sqlite3[core,tool]:$WINARCH-windows
pip install ninja wheel dll-diagnostics

pip freeze | grep dll-diagnostics | sed 's/==/ /' >> versions
# Build proj

git clone --depth 1 $GIT_PROJ src/proj
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
    -DCMAKE_C_COMPILER=cl.exe

cd $TOPDIR
cmake --build build-ecmwf/eccodes --target install

# Build magics

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

cd $TOPDIR
cmake --build build-ecmwf/magics --target install

# Create wheel

rm -fr dist wheelhouse ecmwflibs/share
cp -r install/share ecmwflibs/
mkdir -p ecmwflibs/share/proj
python tools/copy-dlls.py install/bin/MagPlus.dll ecmwflibs/
mkdir -p install/include

./scripts/versions.sh > ecmwflibs/share/versions.json
