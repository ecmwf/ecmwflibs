#!/usr/bin/env bash
set -eaux

# version=$(echo $1| sed 's/\.//')

pip3 install wheel delocate

rm -fr dist wheelhouse
python3 setup.py bdist_wheel
delocate-wheel -w wheelhouse dist/*.whl
