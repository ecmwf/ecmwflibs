#!/bin/bash
set -x
version=$1

brew install python@$1
# echo ::add-path::/opt/homebrew/opt/python@$VERSION/libexec/bin

echo /opt/homebrew/opt/python@$version/libexec/bin >> $GITHUB_PATH

echo $GITHUB_PATH
cat $GITHUB_PATH
ls -l $GITHUB_PATH
pwd
