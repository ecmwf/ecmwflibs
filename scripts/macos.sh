#!/usr/bin/env bash
set -eaux

source scripts/common.sh

brew install cmake ninja
brew install pango cairo proj pkg-config
brew install netcdf
pip3 install wheel delocate


exit 1
