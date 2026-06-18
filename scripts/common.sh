#!/usr/bin/env bash
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

set -eaux

GIT_ECBUILD=${GIT_ECBUILD:-https://github.com/ecmwf/ecbuild.git}
ECBUILD_VERSION=${ECBUILD_VERSION:-master}

GIT_ECCODES=${GIT_ECCODES:-https://github.com/ecmwf/eccodes.git}
ECCODES_VERSION=${ECCODES_VERSION:-2.46.3}
ECCODES_EXTRA_CMAKE_OPTIONS=${ECCODES_EXTRA_CMAKE_OPTIONS:-"-DENABLE_PNG=ON -DENABLE_JPG=ON"}

GIT_MAGICS=${GIT_MAGICS:-https://github.com/ecmwf/magics.git}
MAGICS_VERSION=${MAGICS_VERSION:-4.16.1}


GIT_SQLITE=https://github.com/sqlite/sqlite.git
SQLITE_VERSION=master

GIT_PROJ=https://github.com/OSGeo/PROJ.git
PROJ_VERSION=master

GIT_AEC=https://github.com/MathisRosenhauer/libaec.git
AEC_VERSION=v1.1.3

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

mkdir -p src
mkdir -p build build-ecmwf build-other
: "${ECMWFLIBS_CLEAN:=1}"
: "${ECMWFLIBS_SYNC_SOURCES:=1}"

if [[ "$ECMWFLIBS_CLEAN" == "1" ]]
then
	rm -fr src/ecbuild src/eccodes src/magics
	find build -mindepth 1 -maxdepth 1 -exec rm -rf {} +
	find build-ecmwf -mindepth 1 -maxdepth 1 -exec rm -rf {} +
	find build-other -mindepth 1 -maxdepth 1 -exec rm -rf {} +
fi

sync_or_clone_repo() {
	local repo_path="$1"
	local repo_url="$2"
	local repo_ref="$3"

	if [[ ! -d "$repo_path/.git" ]]
	then
		rm -fr "$repo_path"
		git clone --branch "$repo_ref" "$repo_url" "$repo_path"
		return
	fi

	if [[ "$ECMWFLIBS_SYNC_SOURCES" != "1" ]]
	then
		return
	fi

	git -C "$repo_path" remote set-url origin "$repo_url"
	git -C "$repo_path" fetch --tags --prune origin

	if git -C "$repo_path" show-ref --verify --quiet "refs/remotes/origin/$repo_ref"
	then
		git -C "$repo_path" checkout -B "$repo_ref" "origin/$repo_ref"
	else
		git -C "$repo_path" checkout "$repo_ref"
	fi
}

sync_or_clone_repo src/ecbuild "$GIT_ECBUILD" "$ECBUILD_VERSION"
sync_or_clone_repo src/eccodes "$GIT_ECCODES" "$ECCODES_VERSION"
sync_or_clone_repo src/magics "$GIT_MAGICS" "$MAGICS_VERSION"

mkdir -p build-ecmwf/eccodes
mkdir -p build-ecmwf/magics

TOPDIR=$(/bin/pwd)

echo "================================================================================"
env | sort
echo "================================================================================"
