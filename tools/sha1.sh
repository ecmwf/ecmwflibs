#!/usr/bin/env bash

here=$(dirname $0)

source $here/../make/VERSIONS.make
eccodes=$(git ls-remote $GIT_ECCODES $ECCODES_VERSION | awk '{print $1;}')
magics=$(git ls-remote $GIT_MAGICS $MAGICS_VERSION | awk '{print $1;}')
echo $eccodes
echo $magics
echo "::set-output name=eccodes::${eccodes}"
echo "::set-output name=magics::${magics}"
