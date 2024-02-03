#!/bin/bash
version=$1

brew install python@$1
echo ::add-path::/opt/homebrew/opt/python@$VERSION/libexec/bin

# echo "$HOME/.local/bin" >> $GITHUB_PATH
