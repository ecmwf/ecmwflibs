#!/usr/bin/env bash
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.
# (rm -fr build-other/netcdf/; cd src/netcdf/; git checkout -- .; git clean -f .)
set -eaux
: > versions

SUDO=""
if [[ $(id -u) -ne 0 ]]
then
    SUDO="sudo"
fi

PKG_MGR=""
if command -v yum >/dev/null 2>&1
then
    PKG_MGR="yum"
elif command -v dnf >/dev/null 2>&1
then
    PKG_MGR="dnf"
else
    echo "Neither yum nor dnf found"
    exit 1
fi

PKG_MGR_INSTALL_OPTS=(-y)
if [[ "$PKG_MGR" == "dnf" ]]
then
    repo_files=(/etc/yum.repos.d/*.repo)
    if grep -Eq '/8\.[0-9]+/' "${repo_files[@]}" 2>/dev/null
    then
        $SUDO sed -i -E 's#/8\.[0-9]+/#/8/#g' "${repo_files[@]}" || true
    fi
    rhel_major=$(rpm -E '%{rhel}' 2>/dev/null || true)
    if [[ -n "$rhel_major" ]]
    then
        PKG_MGR_INSTALL_OPTS+=(--releasever="$rhel_major")
    fi
    PKG_MGR_INSTALL_OPTS+=(--refresh)
    $SUDO dnf clean all || true
fi

pkg_install() {
    local pkg="$1"
    local max_attempts=3
    local attempt=1

    while (( attempt <= max_attempts ))
    do
        if $SUDO $PKG_MGR install "${PKG_MGR_INSTALL_OPTS[@]}" "$pkg"
        then
            return 0
        fi
        if (( attempt == max_attempts ))
        then
            return 1
        fi
        sleep $(( attempt * 5 ))
        attempt=$(( attempt + 1 ))
    done
}

# We want the sqlite3 we just compiled
PATH=$(pwd)/install/bin:$PATH

# The version in master does not compile with disabled curl support
NETCDF_VERSION=v4.6.0

source scripts/common.sh

for p in libpng-devel libtiff-devel fontconfig-devel gobject-introspection-devel expat-devel cairo-devel
do
    pkg_install "$p"
    # There may be a better way
    $SUDO $PKG_MGR install "${PKG_MGR_INSTALL_OPTS[@]}" "$p" 2>&1 > tmp
    cat tmp
    v=$(grep 'already installed' < tmp | awk '{print $2;}' | sed 's/\\d://')
    echo "yum $p $v" >> versions
done


pkg_install flex
pkg_install bison
pkg_install pax-utils # For lddtree

bootstrap_python=$(ls -1d /opt/python/cp3*/bin/python3 | head -1)
bootstrap_pip=$(dirname "$bootstrap_python")/pip3
bootstrap_python_config=$(dirname "$bootstrap_python")/python3-config

$SUDO ln -sf "$bootstrap_python" /usr/local/bin/python3
$SUDO ln -sf "$bootstrap_python_config" /usr/local/bin/python3-config
$SUDO ln -sf "$bootstrap_pip" /usr/local/bin/pip3

$SUDO pip3 install ninja auditwheel meson

$SUDO ln -sf $(dirname "$bootstrap_python")/meson /usr/local/bin/meson
$SUDO ln -sf $(dirname "$bootstrap_python")/ninja /usr/local/bin/ninja

if [[ "$CC" == aarch64* && "$(uname -m)" != aarch64* ]]
then
    # Cross-compiling: keep pkg-config scoped to our own from-source
    # install prefix only. The host's system pkgconfig dirs (/usr/lib64,
    # /usr/lib) only contain host-arch (x86_64) .pc files -- notably
    # Xft/Xrender/X11, pulled in transitively by cairo-devel -- which
    # pango auto-detects (dependency('xft', required: false), no meson
    # option to turn it off) and then fails to link against on the
    # aarch64 target ("File in wrong format"). We don't need X11 support
    # in the wheel, so just don't let pkg-config see those .pc files.
    export PKG_CONFIG_PATH=$TOPDIR/install/lib/pkgconfig:$TOPDIR/install/lib64/pkgconfig:$TOPDIR/install/share/pkgconfig
else
    export PKG_CONFIG_PATH=/usr/lib64/pkgconfig:/usr/lib/pkgconfig:${PKG_CONFIG_PATH:-}
    export PKG_CONFIG_PATH=$TOPDIR/install/lib/pkgconfig:$TOPDIR/install/lib64/pkgconfig:$TOPDIR/install/share/pkgconfig:$PKG_CONFIG_PATH
fi
export LD_LIBRARY_PATH=$TOPDIR/install/lib:$TOPDIR/install/lib64:${LD_LIBRARY_PATH:-}

# meson/autotools only add -L/-rpath-link for a target's *direct*
# dependencies. glib's own test/tool binaries (gtester, gobject-query) and
# harfbuzz's hb-info only declare a direct dependency on libglib/libgobject
# themselves, not on the from-source libs those pull in transitively
# (pcre2, libffi) -- so even though e.g. libpcre2-8.so.0 installs correctly
# into $TOPDIR/install/lib, the linker has no search path telling it where
# to find it and fails with "not found" / undefined reference. Make every
# subsequent build's linker invocations aware of our install prefix.
export LDFLAGS="-L$TOPDIR/install/lib -L$TOPDIR/install/lib64 -Wl,-rpath-link,$TOPDIR/install/lib -Wl,-rpath-link,$TOPDIR/install/lib64 ${LDFLAGS:-}"

# Build sqlite

[[ -d src/sqlite ]] || git clone --depth 1 $GIT_SQLITE src/sqlite

cd src/sqlite
./configure \
	--disable-tcl \
	--prefix=$TOPDIR/install


cd $TOPDIR
make -C src/sqlite install

# Build proj
[[ -d src/proj ]] || git clone $GIT_PROJ src/proj
cd src/proj
git checkout $PROJ_VERSION
cd $TOPDIR

mkdir -p build-other/proj
cd build-other/proj

# PROJ needs to run sqlite3 at build time to generate proj.db, but our
# target sqlite3 CLI can't execute on the build host when cross-compiling,
# and the distro's own sqlite3 links against a mismatched system library.
# Build a native, statically linked one just for this.
[[ -d $TOPDIR/build-other/native-sqlite-src ]] || git clone --depth 1 $GIT_SQLITE $TOPDIR/build-other/native-sqlite-src
(
    cd $TOPDIR/build-other/native-sqlite-src
    CC=/usr/bin/gcc ./configure \
        --disable-tcl \
        --disable-shared \
        --prefix=$TOPDIR/build-other/native-sqlite-install
    make install
)
native_sqlite3=$TOPDIR/build-other/native-sqlite-install/bin/sqlite3

cmake  \
    $TOPDIR/src/proj -GNinja  \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_TIFF=0 \
    -DENABLE_CURL=0 \
    -DBUILD_TESTING=0 \
    -DBUILD_PROJSYNC=0 \
    -DBUILD_SHARED_LIBS=1 \
    -DCMAKE_PREFIX_PATH=$TOPDIR/install \
    -DEXE_SQLITE3=$native_sqlite3 \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

cd $TOPDIR
cmake --build build-other/proj --target install

# Build libaec (required by ecCodes for CCSDS/AEC compression)
[[ -d src/aec ]] || git clone $GIT_AEC src/aec
cd src/aec
git checkout $AEC_VERSION
cd $TOPDIR

mkdir -p build-other/aec
cd build-other/aec

cmake \
    $TOPDIR/src/aec -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_SHARED_LIBS=1 \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

cd $TOPDIR
cmake --build build-other/aec --target install

libaec_config_file=$(find "$TOPDIR/install" -maxdepth 6 \( -name 'libaec-config.cmake' -o -name 'libaecConfig.cmake' \) -print | head -1 || true)

libaec_cmake_dir=""
if [[ -n "$libaec_config_file" ]]
then
    libaec_cmake_dir=$(dirname "$libaec_config_file")
fi

if [[ -z "$libaec_cmake_dir" ]]
then
    echo "Could not find libaec CMake package under $TOPDIR/install"
    find "$TOPDIR/install" -maxdepth 5 \( -name 'libaec-config.cmake' -o -name 'libaecConfig.cmake' \) -print || true
    exit 1
fi

# Build jasper (provides libjasper.so, required by ecCodes)
[[ -d src/jasper ]] || git clone $GIT_JASPER src/jasper
cd src/jasper
git checkout $JASPER_VERSION
cd $TOPDIR

mkdir -p build-other/jasper
cd build-other/jasper

cmake \
    $TOPDIR/src/jasper -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_SHARED_LIBS=1 \
    -DJAS_ENABLE_OPENGL=OFF \
    -DJAS_ENABLE_DOC=OFF \
    -DJAS_ENABLE_PROGRAMS=OFF \
    -DCMAKE_PREFIX_PATH=$TOPDIR/install \
    -DJAS_STDC_VERSION=201710L \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

cd $TOPDIR
cmake --build build-other/jasper --target install

# Build libjpeg-turbo (provides libjpeg.so.62, required by ecCodes JPEG support)
[[ -d src/jpeg ]] || git clone $GIT_JPEG src/jpeg
cd src/jpeg
git checkout $JPEG_VERSION
cd $TOPDIR

mkdir -p build-other/jpeg
cd build-other/jpeg

cmake \
    $TOPDIR/src/jpeg -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_SHARED_LIBS=1 \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

cd $TOPDIR
cmake --build build-other/jpeg --target install

# Build zlib (system zlib-devel is host-arch only, no use when cross-compiling)
[[ -d src/zlib ]] || git clone --depth 1 --branch $ZLIB_VERSION $GIT_ZLIB src/zlib

mkdir -p build-other/zlib
cd build-other/zlib

cmake \
    $TOPDIR/src/zlib -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_SHARED_LIBS=1 \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

cd $TOPDIR
cmake --build build-other/zlib --target install

# Without a cross-file, meson doesn't know it's cross-compiling and its
# sanity check tries to run the freshly built (target-arch) test binary.
meson_cross_file=""
if [[ "$CC" == aarch64* && "$(uname -m)" != aarch64* ]]
then
    meson_cross_file=$TOPDIR/build-other/meson-cross.ini
    cat > "$meson_cross_file" <<EOF
[binaries]
c = '$CC'
cpp = '$CXX'
ar = '${AR:-ar}'
strip = '${STRIP:-strip}'
pkg-config = '${PKG_CONFIG:-pkg-config}'

[built-in options]
# The cross-compiler doesn't search the container's own /usr/include by
# default (it has its own sysroot), but some pkg-config'd deps (e.g.
# fontconfig) assume it's already on the default path and omit it from
# their own Cflags. -idirafter (not -I): it must only be a fallback
# searched after the sysroot, or it shadows the sysroot's own arch-correct
# headers (stdint.h, time.h, ...) with the host's x86_64 ones.
# cairo's has_function('ctime_r') probe (called with extra dependencies)
# misdetects it as absent, so cairo defines its own fallback ctime_r --
# which then conflicts with glibc's real (non-static) declaration. Defining
# HAVE_CTIME_R here closes cairo's #ifndef HAVE_CTIME_R guard directly:
# a command-line -D takes effect before config.h is even included, and
# meson's #mesondefine for an unset value is a commented-out /* #undef */,
# not a live directive, so it can't clear this.
c_args = ['-idirafter', '/usr/include', '-D_DEFAULT_SOURCE', '-DHAVE_CTIME_R=1']
cpp_args = ['-idirafter', '/usr/include', '-D_DEFAULT_SOURCE', '-DHAVE_CTIME_R=1']

[host_machine]
system = 'linux'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'
EOF
fi
meson_cross_opt=""
[[ -n "$meson_cross_file" ]] && meson_cross_opt="--cross-file=$meson_cross_file"

# Build libpng, freetype, expat and fontconfig from source: cairo and pango
# link against them, and (like zlib/HDF5 above) the yum-installed *-devel
# packages only provide host-arch (x86_64) .so files, which fail to link
# when cross-compiling for aarch64.

[[ -d src/libpng ]] || git clone --depth 1 --branch $PNG_VERSION $GIT_PNG src/libpng

mkdir -p build-other/libpng
cd build-other/libpng

cmake \
    $TOPDIR/src/libpng -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_SHARED_LIBS=1 \
    -DPNG_TESTS=OFF \
    -DPNG_TOOLS=OFF \
    -DCMAKE_PREFIX_PATH=$TOPDIR/install \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

cd $TOPDIR
cmake --build build-other/libpng --target install

[[ -d src/freetype ]] || git clone --depth 1 --branch $FREETYPE_VERSION $GIT_FREETYPE src/freetype

mkdir -p build-other/freetype
cd build-other/freetype

cmake \
    $TOPDIR/src/freetype -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_SHARED_LIBS=1 \
    -DFT_DISABLE_HARFBUZZ=TRUE \
    -DFT_DISABLE_BROTLI=TRUE \
    -DCMAKE_PREFIX_PATH=$TOPDIR/install \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

cd $TOPDIR
cmake --build build-other/freetype --target install

[[ -d src/expat ]] || git clone --depth 1 --branch $EXPAT_VERSION $GIT_EXPAT src/expat

mkdir -p build-other/expat
cd build-other/expat

cmake \
    $TOPDIR/src/expat/expat -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_SHARED_LIBS=1 \
    -DEXPAT_BUILD_TESTS=OFF \
    -DEXPAT_BUILD_EXAMPLES=OFF \
    -DEXPAT_BUILD_TOOLS=OFF \
    -DEXPAT_BUILD_DOCS=OFF \
    -DCMAKE_PREFIX_PATH=$TOPDIR/install \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

cd $TOPDIR
cmake --build build-other/expat --target install

# fontconfig needs gperf, a host-side code generator (runs on the build
# machine, not the target, so it's unaffected by cross-compiling).
[[ -d src/fontconfig ]] || git clone --depth 1 --branch $FONTCONFIG_VERSION $GIT_FONTCONFIG src/fontconfig
cd src/fontconfig
meson_setup --prefix=$TOPDIR/install \
    -Dwrap_mode=nofallback \
    -Ddoc=disabled \
    -Dnls=disabled \
    -Dtests=disabled \
    -Dtools=disabled \
    -Dcache-build=disabled \
    $meson_cross_opt \
    $TOPDIR/build-other/fontconfig

cd $TOPDIR
ninja -C build-other/fontconfig install

# Build libffi, pcre2 and glib: pango and harfbuzz's hb-glib bridge both
# need glib/gobject, and the yum-installed glib2-devel is host-arch only
# (same reasoning as the libpng/freetype/fontconfig builds above). glib
# has no CMake/meson-buildable libffi of its own, and needs pcre2 for
# GRegex, so both are built first.
glib_host_opt=""
[[ "$CC" == aarch64* && "$(uname -m)" != aarch64* ]] && glib_host_opt="--host=${CC%-gcc}"

[[ -d src/libffi ]] || git clone --depth 1 --branch $LIBFFI_VERSION $GIT_LIBFFI src/libffi
cd src/libffi
[[ -x configure ]] || ./autogen.sh
cd $TOPDIR

mkdir -p build-other/libffi
cd build-other/libffi
# libffi's configure probes `$CC -print-multi-os-directory` and, for the
# aarch64 cross toolchain, that reports "../lib64" -- silently overriding
# our explicit --libdir back to lib64 unless multi-os-directory support is
# turned off.
$TOPDIR/src/libffi/configure $glib_host_opt \
    --prefix=$TOPDIR/install \
    --libdir=$TOPDIR/install/lib \
    --disable-multi-os-directory \
    --disable-static \
    --enable-shared
# libffi's doc/Makefile hard-codes a call to `missing makeinfo`, and this
# vintage of the automake `missing` script does NOT no-op gracefully when
# the real tool is absent (it propagates makeinfo's "command not found"
# as a build failure) -- so passing MAKEINFO=true on the make command line
# has no effect. The manylinux images don't ship texinfo, so stub the
# binary itself instead.
$SUDO ln -sf /bin/true /usr/local/bin/makeinfo
make -j$(nproc)
make install
cd $TOPDIR

[[ -d src/pcre2 ]] || git clone --depth 1 --branch $PCRE2_VERSION $GIT_PCRE2 src/pcre2

mkdir -p build-other/pcre2
cd build-other/pcre2

cmake \
    $TOPDIR/src/pcre2 -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_SHARED_LIBS=1 \
    -DPCRE2_BUILD_TESTS=OFF \
    -DPCRE2_SUPPORT_JIT=OFF \
    -DCMAKE_PREFIX_PATH=$TOPDIR/install \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

cd $TOPDIR
cmake --build build-other/pcre2 --target install

# gvdb is pulled in by glib as a real git submodule (not a meson wrap
# fetch), so it must be checked out together with glib itself.
[[ -d src/glib ]] || git clone --depth 1 --recurse-submodules --shallow-submodules --branch $GLIB_VERSION $GIT_GLIB src/glib
cd src/glib
meson_setup --prefix=$TOPDIR/install \
    -Dwrap_mode=nofallback \
    -Dlibmount=disabled \
    -Dselinux=disabled \
    -Dlibelf=disabled \
    -Dnls=disabled \
    -Dtests=false \
    -Dinstalled_tests=false \
    -Dman=false \
    -Dgtk_doc=false \
    -Dsysprof=disabled \
    -Ddtrace=false \
    -Dsystemtap=false \
    $meson_cross_opt \
    $TOPDIR/build-other/glib

cd $TOPDIR
ninja -C build-other/glib install

# Build HDF5 (provides libhdf5.so + libhdf5_hl.so, required by netcdf and ecCodes)
[[ -d src/hdf5 ]] || git clone $GIT_HDF5 src/hdf5
cd src/hdf5
git checkout $HDF5_VERSION
cd $TOPDIR

mkdir -p build-other/hdf5
cd build-other/hdf5

cmake \
    $TOPDIR/src/hdf5 -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_SHARED_LIBS=1 \
    -DHDF5_BUILD_HL_LIB=ON \
    -DHDF5_BUILD_TOOLS=OFF \
    -DHDF5_BUILD_EXAMPLES=OFF \
    -DHDF5_BUILD_TESTS=OFF \
    -DHDF5_ENABLE_Z_LIB_SUPPORT=ON \
    -DCMAKE_PREFIX_PATH=$TOPDIR/install \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

cd $TOPDIR
cmake --build build-other/hdf5 --target install

# Build netcdf
[[ -d src/netcdf ]] || git clone  $GIT_NETCDF src/netcdf
cd src/netcdf
git checkout $NETCDF_VERSION

rm -fr $TOPDIR/build-other/netcdf
mkdir -p $TOPDIR/build-other/netcdf
cd $TOPDIR/build-other/netcdf

cmake -GNinja \
    $TOPDIR/src/netcdf \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_DAP=0 \
    -DENABLE_DISKLESS=0 \
    -DBUILD_TESTING:BOOL=OFF \
    -DENABLE_TESTS:BOOL=OFF \
    -DHDF5_ROOT=$TOPDIR/install \
    -DCMAKE_PREFIX_PATH=$TOPDIR/install \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install

cd $TOPDIR
cmake --build build-other/netcdf --target install

# Pixman is needed by cairo

[[ -d src/pixman ]] || git clone --depth 1 $GIT_PIXMAN src/pixman
cd src/pixman
meson_setup --prefix=$TOPDIR/install \
    -Dwrap_mode=nofallback \
    -Dtests=disabled \
    $meson_cross_opt \
    $TOPDIR/build-other/pixman

cd $TOPDIR
ninja -C build-other/pixman install

# Build cairo
# -Dqt=disabled

[[ -d src/cairo ]] || git clone $GIT_CAIRO src/cairo
cd src/cairo
git checkout $CAIRO_VERSION
meson_setup --prefix=$TOPDIR/install \
    -Dwrap_mode=nofallback \
    -Dxlib=disabled \
    -Dxcb=disabled \
    -Dglib=disabled \
    $meson_cross_opt \
    $TOPDIR/build-other/cairo

cd $TOPDIR
ninja -C build-other/cairo install

# Build harfbuzz needed by pango

[[ -d src/harfbuzz ]] || git clone --depth 1 $GIT_HARFBUZZ src/harfbuzz

mkdir -p build-other/harfbuzz
cd src/harfbuzz
meson_setup --prefix=$TOPDIR/install \
    -Dwrap_mode=nofallback \
    -Dtests=disabled \
    $meson_cross_opt \
    $TOPDIR/build-other/harfbuzz

cd $TOPDIR
ninja -C build-other/harfbuzz install

# Build fridibi needed by pango

[[ -d src/fridibi ]] || git clone --depth 1 $GIT_FRIBIDI src/fridibi

mkdir -p build-other/fridibi
cd src/fridibi

meson_setup --prefix=$TOPDIR/install \
    -Dwrap_mode=nofallback \
    -Ddocs=false \
    -Dtests=false \
    $meson_cross_opt \
    $TOPDIR/build-other/fridibi

cd $TOPDIR
ninja -C build-other/fridibi install

# Build pango

# Versions after 1.43.0 require versions of glib2 higher than
# the one in the dockcross image

# We undefine G_LOG_USE_STRUCTURED because otherwise we will have a
# undefined symbol g_log_structured_standard() when running on recent
# docker images with recent versions of glib
[[ -d src/pango ]] || git clone --branch 1.43.0 $GIT_PANGO src/pango
# cd src/pango
# git checkout 1.43.0

sed 's/.*G_LOG_USE_STRUCTURED.*//' < src/pango/meson.build > src/pango/meson.build.patched
cp src/pango/meson.build.patched src/pango/meson.build
sed 's/.*G_LOG_USE_STRUCTURED.*//' < src/pango/pango/meson.build > src/pango/pango/meson.build.patched
cp src/pango/pango/meson.build.patched src/pango/pango/meson.build

mkdir -p build-other/pango
cd src/pango
meson_setup --prefix=$TOPDIR/install \
    -Dwrap_mode=nofallback \
    $meson_cross_opt \
    $TOPDIR/build-other/pango

cd $TOPDIR
ninja -C build-other/pango install



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
    -DCMAKE_PREFIX_PATH="$TOPDIR/install;$TOPDIR/install/lib/cmake;$TOPDIR/install/lib64/cmake" \
    -Dlibaec_DIR="$libaec_cmake_dir" \
    -DCMAKE_INSTALL_PREFIX=$TOPDIR/install $ECCODES_EXTRA_CMAKE_OPTIONS

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

lddtree install/lib*/libMagPlus.so
rm -fr dist wheelhouse ecmwflibs/share
cp -r install/share ecmwflibs/
rm -fr ecmwflibs/share/magics/efas
cp install/lib64/*.so install/lib/
for f in install/lib/*.so
do
    strip --strip-debug "$f" || echo "warning: strip failed on $f, leaving it unstripped"
done

./scripts/versions.sh > ecmwflibs/versions.txt
