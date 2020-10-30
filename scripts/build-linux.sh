#!/usr/bin/env bash
set -eaux

INSTALL_NETCDF=${INSTALL_NETCDF:=1}
INSTALL_GOBJECTS=${INSTALL_GOBJECTS:=1}
FIX_LIBCURL=${FIX_LIBCURL:=1}

source scripts/common.sh

if [[ $FIX_LIBCURL -eq 1 ]]
then
    # There are two copies of libcurl, this confuses yum
    rm /usr/local/lib/libcurl.*
    ldconfig
fi

yum install -y libpng-devel
yum install -y libtiff-devel
yum install -y fontconfig-devel

if [[ $INSTALL_GOBJECTS -eq 1 ]]
then
    yum install -y gobject-introspection-devel
fi

yum install -y libjasper-devel
yum install -y flex bison
yum install -y pax-utils # For lddtree

ln -s /opt/python/cp36-cp36m/bin/python /usr/local/bin/python3
ln -s /opt/python/cp36-cp36m/bin/python3-config /usr/local/bin/python3-config
ln -s /opt/python/cp36-cp36m/bin/pip /usr/local/bin/pip3

pip3 install ninja auditwheel meson

ln -s /opt/python/cp36-cp36m/bin/meson /usr/local/bin/meson
ln -s /opt/python/cp36-cp36m/bin/ninja /usr/local/bin/ninja

# Make sure the right libtool is used (installing gobject-... changes libtool)

PATH=$TOPDIR/install/bin:/usr/bin:$PATH
NOCONFIGURE=1
PKG_CONFIG_PATH=$TOPDIR/install/lib/pkgconfig:$TOPDIR/install/lib64/pkgconfig:$PKG_CONFIG_PATH
LD_LIBRARY_PATH=$TOPDIR/install/lib:$TOPDIR/install/lib64:$LD_LIBRARY_PATH

# Build netcdf without curl

if [[ $INSTALL_NETCDF -eq 1 ]]
then
    yum install -y netcdf-devel
else

    yum install -y hdf5-devel

    git clone  $GIT_NETCDF src/netcdf
    cd src/netcdf
    git checkout $NETCDF_VERSION

    mkdir -p $TOPDIR/build-other/netcdf
    cd $TOPDIR/build-other/netcdf

    cmake -GNinja \
        $TOPDIR/src/netcdf \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DENABLE_DAP=0 \
        -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

    cd $TOPDIR
    cmake --build build-other/netcdf --target install

fi

# Pixman is needed by cairo

git clone --depth 1 $GIT_PIXMAN src/pixman
cd src/pixman
./autogen.sh
./configure --prefix=$TOPDIR/install

cd $TOPDIR
make -C src/pixman install

# Build cairo

git clone --depth 1 $GIT_CAIRO src/cairo
cd src/cairo
./autogen.sh
./configure \
    --disable-xlib \
    --disable-xcb \
    --disable-qt \
    --disable-quartz \
    --disable-gl \
    --disable-gobject \
    --prefix=$TOPDIR/install

cd $TOPDIR
make -C src/cairo install

# Build harfbuzz needed by pango

git clone --depth 1 $GIT_HARFBUZZ src/harfbuzz

mkdir -p build-other/harfbuzz
cd src/harfbuzz
meson setup --prefix=$TOPDIR/install \
    -Dintrospection=disabled \
    -Dwrap_mode=nofallback \
    $TOPDIR/build-other/harfbuzz

cd $TOPDIR
ninja -C build-other/harfbuzz install

# Build fridibi needed by pango

git clone --depth 1 $GIT_FRIBIDI src/fridibi

mkdir -p build-other/fridibi
cd src/fridibi
meson setup --prefix=$TOPDIR/install \
    -Dintrospection=disabled \
    -Dwrap_mode=nofallback \
    -Ddocs=false \
    $TOPDIR/build-other/fridibi

cd $TOPDIR
ninja -C build-other/fridibi install

# Build pango

# Versions after 1.43.0 require versions of glib2 higher than
# the one in the dockcross image

# We undefine G_LOG_USE_STRUCTURED because otherwise we will have a
# undefined symbol g_log_structured_standard() when running on recent
# docker images with recent versions of glib
git clone --branch 1.43.0 $GIT_PANGO src/pango
# cd src/pango
# git checkout 1.43.0

sed 's/.*G_LOG_USE_STRUCTURED.*//' < src/pango/meson.build > src/pango/meson.build.patched
cp src/pango/meson.build.patched src/pango/meson.build
sed 's/.*G_LOG_USE_STRUCTURED.*//' < src/pango/pango/meson.build > src/pango/pango/meson.build.patched
cp src/pango/pango/meson.build.patched src/pango/pango/meson.build

mkdir -p build-other/pango
cd src/pango
meson setup --prefix=$TOPDIR/install \
    -Dwrap_mode=nofallback \
    $TOPDIR/build-other/pango

cd $TOPDIR
ninja -C build-other/pango install


# Build sqlite

git clone --depth 1 $GIT_SQLITE src/sqlite

cd src/sqlite
./configure \
	--disable-tcl \
	--prefix=$TOPDIR/install

cd $TOPDIR
make -C src/sqlite install

# Build proj

git clone --depth 1 $GIT_PROJ src/proj

cd src/proj
./autogen.sh
./configure \
    --prefix=$TOPDIR/install \
    --disable-tiff \
    --with-curl=no

cd $TOPDIR
make -C src/proj install

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

rm -fr dist wheelhouse ecmwflibs/share
cp -r install/share ecmwflibs/
cp install/lib64/*.so install/lib/
strip --strip-debug install/lib/*.so
python3 setup.py bdist_wheel
auditwheel repair dist/*.whl
