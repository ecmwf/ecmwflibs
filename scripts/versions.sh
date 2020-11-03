#!/usr/bin/env bash
set -eaux
cat versions
cd src

for n in *
do
  cd $n
  url=$(git remote -v | head -1 | awk '{print $2;}')
  sha1=$(git rev-parse HEAD)
  echo git $url $sha1
  cd ..
done

cd ..
