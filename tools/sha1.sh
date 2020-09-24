#!/usr/bin/env bash

source make/VERSIONS.make
eccodes=$(git ls-remote $GIT_ECCODES $ECCODES_VERSION | awk '{print $1;}')
magics=$(git ls-remote $GIT_MAGICS $MAGICS_VERSION | awk '{print $1;}')
echo "::set-output name=eccodes:$eccodes"
echo "::set-output name=magics:$magics"
