#!/usr/bin/env bash
set -eaux

FIX_LIBCURL=1
INSTALL_GOBJECTS=1
INSTALL_HDF5=1

./scripts/build-linux.sh
