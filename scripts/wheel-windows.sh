#!/usr/bin/env bash
set -eaux

# version=$(echo $1| sed 's/\.//')

pip install wheel

rm -fr dist wheelhouse
python setup.py bdist_wheel
