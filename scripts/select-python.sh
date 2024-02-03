#!/bin/bash
set -x
version=$1

brew install python@$1
# echo ::add-path::/opt/homebrew/opt/python@$VERSION/libexec/bin

echo /opt/homebrew/opt/python@$version/libexec/bin >> $GITHUB_PATH

ls -l /opt/homebrew/opt/python@$version/libexec/bin
