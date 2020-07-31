#!/usr/bin/env bash
PATH=/opt/python/cp36-cp36m/bin:$PATH
pip3 install --upgrade ../wheelhouse/*.whl
pip3 install magics
python3 plot.py
