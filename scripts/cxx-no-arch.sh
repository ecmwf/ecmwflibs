#!/bin/bash
set -ex

for arg do
    shift
    if [[ "$arg" = "-arch" ]]
        shift
        continue
    fi
    set -- "$@" "$arg"
done

clang++ "$@"
