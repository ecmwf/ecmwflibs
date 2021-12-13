#!/usr/bin/env bash
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

set -eaux

for p in netcdf-c[core,netcdf-4,hdf5]
do
    echo $p:$WINARCH-windows
    vcpkg install $p:$WINARCH-windows
done

cd tests

cmake . \
    -G"NMake Makefiles"  \
    -DCMAKE_TOOLCHAIN_FILE=/c/vcpkg/scripts/buildsystems/vcpkg.cmake \
    -DCMAKE_C_COMPILER=cl.exe

cmake --build .

ls -lrt

./open_netcdf test.nc4
