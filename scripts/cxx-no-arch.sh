#!/bin/bash
set -ex

for arg do
    shift
    if [[ "$arg" = "-arch" ]]
    then
        shift
        continue
    fi
    set -- "$@" "$arg"
done

clang++ "$@"
