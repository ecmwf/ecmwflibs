#!/usr/bin/env bash
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

set -eaux

GIT_ECBUILD=https://github.com/ecmwf/ecbuild.git
ECBUILD_VERSION=master

GIT_ECCODES=https://github.com/ecmwf/eccodes.git
ECCODES_VERSION=2.48.0
ECCODES_EXTRA_CMAKE_OPTIONS="-DENABLE_PNG=ON -DENABLE_JPG=ON"

GIT_MAGICS=https://github.com/ecmwf/magics.git
MAGICS_VERSION=4.16.3


GIT_SQLITE=https://github.com/sqlite/sqlite.git
SQLITE_VERSION=master

GIT_PROJ=https://github.com/OSGeo/PROJ.git
PROJ_VERSION=master

GIT_AEC=https://github.com/MathisRosenhauer/libaec.git
AEC_VERSION=v1.1.7

GIT_ZLIB=https://github.com/madler/zlib.git
ZLIB_VERSION=v1.3.1

GIT_PNG=https://github.com/pnggroup/libpng.git
PNG_VERSION=v1.6.45

GIT_FREETYPE=https://gitlab.freedesktop.org/freetype/freetype.git
FREETYPE_VERSION=VER-2-13-3

GIT_EXPAT=https://github.com/libexpat/libexpat.git
EXPAT_VERSION=R_2_6_4

GIT_FONTCONFIG=https://gitlab.freedesktop.org/fontconfig/fontconfig.git
FONTCONFIG_VERSION=2.16.2

GIT_LIBFFI=https://github.com/libffi/libffi.git
LIBFFI_VERSION=v3.4.6

GIT_PCRE2=https://github.com/PCRE2Project/pcre2.git
PCRE2_VERSION=pcre2-10.44

GIT_GLIB=https://gitlab.gnome.org/GNOME/glib.git
GLIB_VERSION=2.78.6

GIT_PIXMAN=https://gitlab.freedesktop.org/pixman/pixman
PIXMAN_VERSION=master

GIT_CAIRO=https://gitlab.freedesktop.org/cairo/cairo
CAIRO_VERSION=1.17.6

GIT_HARFBUZZ=https://github.com/harfbuzz/harfbuzz.git
HARFBUZZ_VERSION=master

GIT_FRIBIDI=https://github.com/fribidi/fribidi.git
FRIBIDI_VERSION=master

GIT_PANGO=https://gitlab.gnome.org/GNOME/pango.git
PANGO_VERSION=master

GIT_UDUNITS=https://github.com/b8raoult/UDUNITS-2.git
UDUNITS_VERSION=master

GIT_NETCDF=https://github.com/Unidata/netcdf-c.git
NETCDF_VERSION=${NETCDF_VERSION:=master}

GIT_HDF5=https://github.com/HDFGroup/hdf5.git
HDF5_VERSION=${HDF5_VERSION:=hdf5_1_14_6}

GIT_JPEG=https://github.com/libjpeg-turbo/libjpeg-turbo.git
JPEG_VERSION=3.1.4.1

GIT_JASPER=https://github.com/jasper-software/jasper.git
JASPER_VERSION=version-4.2.9

# CI caches install/, build-other/ and src/ across runs so an unrelated
# script edit doesn't force a ~20min rebuild of every already-working
# dependency. A restored build-other/X is already `meson setup` and needs
# --reconfigure (plain `meson setup` errors out on an existing build dir);
# --reconfigure also makes sure a cache hit still picks up new flags (e.g.
# a changed LDFLAGS/meson option), rather than silently keeping stale ones.
meson_setup() {
    local builddir="${!#}"
    if [[ -f "$builddir/build.ninja" ]]
    then
        meson setup --reconfigure "$@"
    else
        meson setup "$@"
    fi
}

mkdir -p src
rm -fr src/ecbuild src/eccodes src/magics
mkdir -p build build-ecmwf
find build -mindepth 1 -maxdepth 1 -exec rm -rf {} +
find build-ecmwf -mindepth 1 -maxdepth 1 -exec rm -rf {} +

git clone --branch $ECBUILD_VERSION $GIT_ECBUILD src/ecbuild
git clone --branch $ECCODES_VERSION $GIT_ECCODES src/eccodes
git clone --branch $MAGICS_VERSION $GIT_MAGICS src/magics

mkdir -p build-ecmwf/eccodes
mkdir -p build-ecmwf/magics

TOPDIR=$(/bin/pwd)

echo "================================================================================"
env | sort
echo "================================================================================"
