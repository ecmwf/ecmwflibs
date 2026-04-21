#!/usr/bin/env bash
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

set -eaux

version=$(echo $1| sed 's/\.//')

pybin=$(ls -1d /opt/python/cp${version}-cp${version}*/bin/python3 2>/dev/null | head -1)
if [[ -z "$pybin" ]]
then
	pybin=$(ls -1d /opt/python/cp${version}t-cp${version}t*/bin/python3 2>/dev/null | head -1)
fi
if [[ -z "$pybin" ]]
then
	echo "Cannot find Python binary for cp${version} under /opt/python"
	exit 1
fi

TOPDIR=$(/bin/pwd)

SYSTEM_LIB_DIRS=(/lib64 /usr/lib64 /usr/local/lib64 /lib /usr/lib /usr/local/lib)

stage_runtime_library() {
	local soname="$1"
	local src=""

	for d in "${SYSTEM_LIB_DIRS[@]}"
	do
		if [[ -e "$d/$soname" ]]
		then
			src="$d/$soname"
			break
		fi
	done

	if [[ -z "$src" ]]
	then
		for d in "${SYSTEM_LIB_DIRS[@]}"
		do
			src=$(find "$d" -maxdepth 1 -name "${soname}*" -print | head -1 || true)
			if [[ -n "$src" ]]
			then
				break
			fi
		done
	fi

	if [[ -z "$src" ]]
	then
		echo "Could not stage runtime library: $soname"
		return 0
	fi

	mkdir -p "$TOPDIR/install/lib"
	cp -a "$src" "$TOPDIR/install/lib/"

	if [[ -L "$src" ]]
	then
		local resolved
		resolved=$(readlink -f "$src")
		if [[ -n "$resolved" && -e "$resolved" ]]
		then
			cp -a "$resolved" "$TOPDIR/install/lib/"
		fi
	fi
}

stage_runtime_library libhdf5_hl.so.8
stage_runtime_library libjpeg.so.62

export LD_LIBRARY_PATH=$TOPDIR/install/lib:$TOPDIR/install/lib64:/usr/lib64:/lib64:/usr/lib:/lib:${LD_LIBRARY_PATH:-}

rm -fr dist wheelhouse
$pybin setup.py bdist_wheel

# Do it twice to get the list of libraries

auditwheel repair dist/*.whl
unzip -l wheelhouse/*.whl | grep 'ecmwflibs.libs/' > libs
pip3 install -r tools/requirements.txt

python3 ./tools/copy-licences.py libs

rm -fr dist wheelhouse
$pybin setup.py bdist_wheel
auditwheel repair dist/*.whl
rm -fr dist
