#!/usr/bin/env bash
set -eaux

source scripts/common.sh

git clone git://github.com/ninja-build/ninja.git
cd ninja
git checkout release

PATH=$TOPDIR/ninja:$PATH
./configure.py --bootstrap

[[ -d vcpkg ]] || git clone --depth 1 https://github.com/microsoft/vcpkg

[[ -f vcpkg/vcpkg  ]] || ./vcpkg/bootstrap-vcpkg.sh -useSystemBinaries
PATH=$TOPDIR/vcpkg:$PATH



# vcpkg install expat --debug
vcpkg install netcdf-c
vcpkg install pango
vcpkg install sqlite3[core,tool]

# Build proj7

git clone --depth 1 $GIT_PROJ src/proj7
mkdir -p build-other/proj7
cd build-other/proj7

    # -DSQLITE3_BIN_PATH=C:/vcpkg/packages/sqlite3_${WINARCH}-windows/tools/sqlite3.exe \

cmake  \
    $TOPDIR/src/proj7 -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_TIFF=0 \
    -DENABLE_CURL=0 \
    -DBUILD_TESTING=0 \
    -DBUILD_PROJSYNC=0 \
    -DBUILD_SHARED_LIBS=1 \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install \
    -DCMAKE_TOOLCHAIN_FILE=$TOPDIR/vcpkg/scripts/buildsystems/vcpkg.cmake \

cd $TOPDIR
cmake --build build-other/proj7 --target install

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
    -DCMAKE_TOOLCHAIN_FILE=$TOPDIR/vcpkg/scripts/buildsystems/vcpkg.cmake

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
    -DCMAKE_TOOLCHAIN_FILE=$TOPDIR/vcpkg/scripts/buildsystems/vcpkg.cmake

cd $TOPDIR
cmake --build build-ecmwf/magics --target install

# Create wheel

rm -fr dist wheelhouse ecmwflibs/share
cp -r install/share ecmwflibs/
cp install/lib64/*.so install/lib/ || true
strip --strip-debug install/lib/*.so
python3 setup.py bdist_wheel
auditwheel repair dist/*.whl
unzip -l wheelhouse/*.whl | grep ecmwflibs.libs/
