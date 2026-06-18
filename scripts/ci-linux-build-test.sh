#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]
then
    echo "Usage: $0 <wheel-tag> <python-version> [<python-version> ...]"
    echo "Example: $0 manylinux2014 3.10 3.11 3.12 3.13"
    exit 1
fi

wheel_tag=$1
shift
versions=("$@")

TOPDIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$TOPDIR"

find_pybin() {
    local version=$1
    local compact
    compact=$(echo "$version" | sed 's/\.//')

    local pybin
    pybin=$(ls -1d /opt/python/cp${compact}-cp${compact}*/bin/python3 2>/dev/null | head -1 || true)
    if [[ -z "$pybin" ]]
    then
        pybin=$(ls -1d /opt/python/cp${compact}t-cp${compact}t*/bin/python3 2>/dev/null | head -1 || true)
    fi

    if [[ -z "$pybin" ]]
    then
        echo "Cannot find Python binary for $version under /opt/python" >&2
        exit 1
    fi

    echo "$pybin"
}

echo "==> Building native dependencies and libraries"
./scripts/build-linux.sh

mkdir -p "wheelhouse-all/$wheel_tag"

for version in "${versions[@]}"
do
    echo "==> Building wheel for Python $version ($wheel_tag)"
    ./scripts/wheel-linux.sh "$version"
    mkdir -p "wheelhouse-all/$wheel_tag/$version"
    cp wheelhouse/*.whl "wheelhouse-all/$wheel_tag/$version/"
done

echo "==> Downloading test data"
curl -L https://get.ecmwf.int/repository/test-data/metview/gallery/2m_temperature.grib -o tests/data.grib
curl -L https://github.com/ecmwf/climetlab/raw/main/docs/examples/test.grib -o tests/climetlab.grib
curl -L https://github.com/ecmwf/climetlab/raw/main/docs/examples/test.nc -o tests/climetlab.nc

for version in "${versions[@]}"
do
    pybin=$(find_pybin "$version")

    echo "==> Testing wheel for Python $version ($wheel_tag)"
    "$pybin" -m pip install --upgrade pip
    "$pybin" -m pip install -r tests/requirements.txt
    "$pybin" -m pip install --force-reinstall "wheelhouse-all/$wheel_tag/$version"/*.whl

    ecmwflibs_site=$(
        "$pybin" -c 'import importlib.util; spec = importlib.util.find_spec("ecmwflibs"); print(spec.origin.rsplit("/", 2)[0] if spec and spec.origin else "")'
    )
    ecmwflibs_libs="${ecmwflibs_site}.libs"

    (
        cd tests
        export ECCODES_PYTHON_USE_FINDLIBS=1
        export ECCODES_DIR="$TOPDIR/install"
        export LD_LIBRARY_PATH="$ecmwflibs_libs:$TOPDIR/install/lib:$TOPDIR/install/lib64:${LD_LIBRARY_PATH:-}"
        "$pybin" -m pytest -v -s
    )
done

echo "==> Done. Wheels available under wheelhouse-all/$wheel_tag"
