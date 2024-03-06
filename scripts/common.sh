#!/usr/bin/env bash
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

set -eaux
rm -f versions

GIT_ECBUILD=https://github.com/ecmwf/ecbuild.git
ECBUILD_VERSION=master

GIT_ECCODES=https://github.com/ecmwf/eccodes.git
ECCODES_VERSION=2.34.1
ECCODES_EXTRA_CMAKE_OPTIONS="-DENABLE_PNG=ON -DENABLE_JPG=ON"

GIT_MAGICS=https://github.com/ecmwf/magics.git
# MAGICS_VERSION=4.14.2
MAGICS_VERSION=develop


GIT_SQLITE=https://github.com/sqlite/sqlite.git
SQLITE_VERSION=master

GIT_PROJ=https://github.com/OSGeo/PROJ.git
PROJ_VERSION=master

GIT_AEC=https://github.com/MathisRosenhauer/libaec.git
AEC_VERSION=master

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
HDF5_VERSION=${HDF5_VERSION:=hdf5-1_10_5}

rm -fr src build build-ecmwf

git clone --branch $ECBUILD_VERSION $GIT_ECBUILD src/ecbuild
git clone --branch $ECCODES_VERSION $GIT_ECCODES src/eccodes
git clone --branch $MAGICS_VERSION $GIT_MAGICS src/magics

mkdir -p build-ecmwf/eccodes
mkdir -p build-ecmwf/magics

TOPDIR=$(/bin/pwd)

echo "================================================================================"
env | sort
echo "================================================================================"
