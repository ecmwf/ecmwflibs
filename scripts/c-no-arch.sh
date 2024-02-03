#!/bin/bash
set -ex

skip=0
for c do
    shift
    if [[ "$c" == "-arch" ]]; then
        skip=1
        continue
    fi
    if [[ $skip -eq 1 ]]; then
        skip=0
        continue
    fi
    set -- "$@" "$c"
done

clang "$@"
