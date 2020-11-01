#!/usr/bin/env bash
set -eaux

source scripts/common.sh


sudo yum install -y libpng-devel
sudo yum install -y libtiff-devel
sudo yum install -y fontconfig-devel

sudo yum install -y expat-devel
sudo yum install -y cairo-devel

sudo yum install -y libjasper-devel
sudo yum install -y flex bison
sudo yum install -y pax-utils # For lddtree

sudo ln -sf /opt/python/cp36-cp36m/bin/python /usr/local/bin/python3
sudo ln -sf /opt/python/cp36-cp36m/bin/python3-config /usr/local/bin/python3-config
sudo ln -sf /opt/python/cp36-cp36m/bin/pip /usr/local/bin/pip3

sudo pip3 install ninja auditwheel meson

sudo ln -sf /opt/python/cp36-cp36m/bin/meson /usr/local/bin/meson
sudo ln -sf /opt/python/cp36-cp36m/bin/ninja /usr/local/bin/ninja

# Make sure the right libtool is used (installing gobject-... changes libtool)

# PATH=$TOPDIR/install/bin:/usr/bin:$PATH
# NOCONFIGURE=1
PKG_CONFIG_PATH=/usr/lib64/pkgconfig:/usr/lib/pkgconfig:$PKG_CONFIG_PATH
PKG_CONFIG_PATH=$TOPDIR/install/lib/pkgconfig:$TOPDIR/install/lib64/pkgconfig:$PKG_CONFIG_PATH
LD_LIBRARY_PATH=$TOPDIR/install/lib:$TOPDIR/install/lib64:$LD_LIBRARY_PATH


################################################################
git clone  $GIT_HDF5 src/hdf5
cd src/hdf5
git checkout $HDF5_VERSION

mkdir -p $TOPDIR/build-other/hdf5
cd $TOPDIR/build-other/hdf5

cmake -GNinja \
    $TOPDIR/src/hdf5 \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_TESTING=OFF \
    -DDISABLE_STATIC_LIBS=ON \
    -DHDF5_BUILD_EXAMPLES=OFF \
    -DHDF5_BUILD_TOOLS=OFF \
    -DHDF5_BUILD_CPP_LIB=OFF \
    -DHDF5_ENABLE_PARALLEL=OFF \
    -DHDF5_ENABLE_Z_LIB_SUPPORT=ON \
    -DHDF5_ENABLE_SZIP_SUPPORT=OFF \
    -DHDF5_ENABLE_SZIP_ENCODING=OFF \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

cd $TOPDIR
cmake --build build-other/hdf5 --target install

################################################################

git clone  $GIT_NETCDF src/netcdf
cd src/netcdf
git checkout $NETCDF_VERSION


mkdir -p $TOPDIR/build-other/netcdf
cd $TOPDIR/build-other/netcdf

cmake -GNinja \
    $TOPDIR/src/netcdf \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_DAP=OFF \
    -DENABLE_NCZARR=OFF \
    -DENABLE_DISKLESS=OFF \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

cd $TOPDIR
cmake --build build-other/netcdf --target install

# fi
yum install -y pango-devel
# Pixman is needed by cairo

# git clone --depth 1 $GIT_PIXMAN src/pixman
# cd src/pixman
# meson setup --prefix=$TOPDIR/install \
#     -Dintrospection=disabled \
#     -Dwrap_mode=nofallback \
#     $TOPDIR/build-other/pixman

# cd $TOPDIR
# ninja -C build-other/pixman install


# # Build cairo

# git clone --depth 1 $GIT_CAIRO src/cairo
# cd src/cairo
# meson setup --prefix=$TOPDIR/install \
#     -Dintrospection=disabled \
#     -Dwrap_mode=nofallback \
#     -Dxlib=disabled \
#     -Dxcb=disabled \
#     -Dqt=disabled \
#     -Dgl-backend=disabled \
#     $TOPDIR/build-other/cairo

# cd $TOPDIR
# ninja -C build-other/cairo install

# fi

# if [[ $INSTALL_PANGO -eq 1 ]]
# then
#     sudo yum install -y pango-devel
# else

# # Build harfbuzz needed by pango

# git clone --depth 1 $GIT_HARFBUZZ src/harfbuzz

# mkdir -p build-other/harfbuzz
# cd src/harfbuzz
# meson setup --prefix=$TOPDIR/install \
#     -Dintrospection=disabled \
#     -Dwrap_mode=nofallback \
#     $TOPDIR/build-other/harfbuzz

# cd $TOPDIR
# ninja -C build-other/harfbuzz install

# # Build fridibi needed by pango

# git clone --depth 1 $GIT_FRIBIDI src/fridibi

# mkdir -p build-other/fridibi
# cd src/fridibi
# meson setup --prefix=$TOPDIR/install \
#     -Dintrospection=disabled \
#     -Dwrap_mode=nofallback \
#     -Ddocs=false \
#     $TOPDIR/build-other/fridibi

# cd $TOPDIR
# ninja -C build-other/fridibi install

# # Build pango

# # Versions after 1.43.0 require versions of glib2 higher than
# # the one in the dockcross image

# # We undefine G_LOG_USE_STRUCTURED because otherwise we will have a
# # undefined symbol g_log_structured_standard() when running on recent
# # docker images with recent versions of glib
# git clone --branch 1.43.0 $GIT_PANGO src/pango
# # cd src/pango
# # git checkout 1.43.0

# sed 's/.*G_LOG_USE_STRUCTURED.*//' < src/pango/meson.build > src/pango/meson.build.patched
# cp src/pango/meson.build.patched src/pango/meson.build
# sed 's/.*G_LOG_USE_STRUCTURED.*//' < src/pango/pango/meson.build > src/pango/pango/meson.build.patched
# cp src/pango/pango/meson.build.patched src/pango/pango/meson.build

# mkdir -p build-other/pango
# cd src/pango
# meson setup --prefix=$TOPDIR/install \
#     -Dwrap_mode=nofallback \
#     $TOPDIR/build-other/pango

# cd $TOPDIR
# ninja -C build-other/pango install

# fi

sudo yum install -y sqlite-devel

# if [[ $INSTALL_SQLITE -eq 1 ]]
# then
#     sudo yum install -y sqlite-devel
# else

# Build sqlite

git clone --depth 1 $GIT_SQLITE src/sqlite

cd src/sqlite
./configure \
	--disable-tcl \
	--prefix=$TOPDIR/install

# if [[ $FIX_SHELL_TCL -eq 1 ]]
# then
#     sed -i 's/ rb/ r/' tool/*.tcl
# fi

cd $TOPDIR
make -C src/sqlite install

# fi

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
unzip -l wheelhouse/*.whl | grep ecmwflibs.libs/
