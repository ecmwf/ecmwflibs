#!/usr/bin/env bash
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

for p in expat netcdf-c[core,netcdf-4] pango sqlite3[core,tool]
do
    vcpkg install $p:$WINARCH-windows
    n=$(echo $p | sed 's/\[.*//')
    v=$(vcpkg list $n | awk '{print $2;}')
    echo "vcpkg $n $v" >> versions
done

exit
# set -eaux
set -x
/c/msys64/mingw32/bin/pkg-config.exe --version
/c/msys64/mingw64/bin/pkg-config.exe --version
/c/msys64/usr/bin/pkg-config.exe --version
/c/rtools40/mingw32/bin/pkg-config.exe --version
/c/rtools40/mingw64/bin/pkg-config.exe --version
/c/rtools40/ucrt64/bin/pkg-config.exe --version
/c/Strawberry/perl/bin/pkg-config --version
/c/Strawberry/perl/bin/pkg-config.bat --version





exit

vcpkg install glib pango

find /c/vcpkg -name cairo.h -print

find /c/vcpkg -name glib-object.h -print
