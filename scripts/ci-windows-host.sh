#!/usr/bin/env bash
set -euo pipefail

: "${WINARCH:=x64}"

if [[ $# -eq 0 ]]
then
    versions=("3.10" "3.11" "3.12" "3.13" "3.14")
else
    versions=("$@")
fi

if ! command -v py >/dev/null 2>&1
then
    echo "Windows Python launcher 'py' not found. Install Python for all target versions first."
    exit 1
fi

echo "==> Running Windows build for WINARCH=$WINARCH"
./scripts/build-windows.sh

for version in "${versions[@]}"
do
    echo "==> Building wheel for Python $version (WINARCH=$WINARCH)"
    ./scripts/wheel-windows.sh "$version"

    echo "==> Testing wheel for Python $version"
    py -"$version" -m pip install --upgrade pip
    py -"$version" -m pip install -r tests/requirements.txt
    py -"$version" -m pip install --force-reinstall wheelhouse/*.whl

    (
        cd tests
        py -"$version" -m pytest --verbose -s
    )
done

echo "==> Windows host build/test completed"
