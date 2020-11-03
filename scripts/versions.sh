#!/usr/bin/env bash
set -eaux
cd src

for n in *
do
  cd $n
  url=$(git remote -v | head -1 | awk '{print $2;}')
  sha1=$(git rev-parse HEAD)
  echo $url $sha1 >> versions
  cd ..
done

cd ..

python -c '
import json
x = {}
with open("versions") as f:
    for line in f:
        k, v = line.strip().split(" ")
        x[k] = v
print(json.dumps(x), indent=4)
'
