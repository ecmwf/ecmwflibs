#!/bin/bash
set -xe
version=$1

brew install python@$1

echo /opt/homebrew/opt/python@$version/libexec/bin >> $GITHUB_PATH

ls -l /opt/homebrew/opt/python@$version/libexec/bin

# Looks like python3 is not a symlink to python in 3.11

if [[ ! -f /opt/homebrew/opt/python@$version/libexec/bin/python3 ]]
then
    ln -s /opt/homebrew/opt/python@$version/libexec/bin/python /opt/homebrew/opt/python@$version/libexec/bin/python3
fi

if [[ ! -f /opt/homebrew/opt/python@$version/libexec/bin/pip3 ]]
then
    ln -s /opt/homebrew/opt/python@$version/libexec/bin/pip /opt/homebrew/opt/python@$version/libexec/bin/pip3
fi

ls -l
