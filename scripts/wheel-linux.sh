#!/usr/bin/env bash
set -eaux

version=$(echo $1| sed 's/\.//')

rm -fr wheelhouse
/opt/python/cp${version}-cp${version}*/bin/python3 setup.py bdist_wheel
auditwheel repair dist/*.whl
rm -fr dist
