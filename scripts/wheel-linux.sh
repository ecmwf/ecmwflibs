#!/usr/bin/env bash
set -eaux

version=$(echo $1| sed 's/\.//')

TOPDIR=$(/bin/pwd)

LD_LIBRARY_PATH=$TOPDIR/install/lib:$TOPDIR/install/lib64:$LD_LIBRARY_PATH

rm -fr dist wheelhouse
/opt/python/cp${version}-cp${version}*/bin/python3 setup.py bdist_wheel
auditwheel repair dist/*.whl
rm -fr dist
