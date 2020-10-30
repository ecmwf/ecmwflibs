#!/usr/bin/env bash
set -eaux

source scripts/common.sh

# There are two copies of libcurl, this confuses yum
rm /usr/local/lib/libcurl.*
ldconfig

yum install -y hdf5-devel
yum install -y libpng-devel
yum install -y libtiff-devel
yum install -y fontconfig-devel
yum install -y gobject-introspection-devel
yum install -y libjasper-devel
yum install -y flex bison
yum install -y pax-utils # For lddtree

ln -s /opt/python/cp36-cp36m/bin/python /usr/local/bin/python3
ln -s /opt/python/cp36-cp36m/bin/python3-config /usr/local/bin/python3-config
ln -s /opt/python/cp36-cp36m/bin/pip /usr/local/bin/pip3

pip3 install ninja auditwheel meson

ln -s /opt/python/cp36-cp36m/bin/meson /usr/local/bin/meson
ln -s /opt/python/cp36-cp36m/bin/ninja /usr/local/bin/ninja


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
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

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
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

cd $TOPDIR
cmake --build build-ecmwf/magics --target install

# Create wheel
# rm -fr dist wheelhouse ecmwflibs/share
# mkdir -p install/share/magics
# cp -r install/share ecmwflibs/
# cp -r /usr/local/Cellar/proj/*/share ecmwflibs/
# strip -S install/lib/*.dylib
# python3 setup.py bdist_wheel
# delocate-wheel -w wheelhouse dist/*.whl
