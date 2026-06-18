#!/usr/bin/env bash
set -euo pipefail

target_arch="$(uname -m)"
run_tests=false
skip_build=false

versions=("3.10" "3.11" "3.12" "3.13" "3.14")

while [[ $# -gt 0 ]]
do
    case "$1" in
        --arch)
            target_arch="$2"
            shift 2
            ;;
        --run-tests)
            run_tests=true
            shift
            ;;
        --skip-build)
            skip_build=true
            shift
            ;;
        --versions)
            shift
            versions=()
            while [[ $# -gt 0 && "$1" != --* ]]
            do
                versions+=("$1")
                shift
            done
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--arch arm64|x86_64] [--run-tests] [--skip-build] [--versions <v1> <v2> ...]"
            exit 1
            ;;
    esac
done

if [[ "$target_arch" != "arm64" && "$target_arch" != "x86_64" ]]
then
    echo "Unsupported --arch '$target_arch'. Use 'arm64' or 'x86_64'."
    exit 1
fi

host_arch="$(uname -m)"

run_arch() {
    if [[ "$target_arch" == "$host_arch" ]]
    then
        "$@"
    else
        arch -"$target_arch" "$@"
    fi
}

if [[ -n "${BREW_BIN:-}" ]]
then
    brew_bin="$BREW_BIN"
else
    if [[ "$target_arch" == "x86_64" && -x /usr/local/bin/brew ]]
    then
        brew_bin=/usr/local/bin/brew
    elif [[ "$target_arch" == "arm64" && -x /opt/homebrew/bin/brew ]]
    then
        brew_bin=/opt/homebrew/bin/brew
    else
        brew_bin="$(command -v brew || true)"
    fi
fi

if [[ -z "$brew_bin" || ! -x "$brew_bin" ]]
then
    echo "Could not find brew executable for arch '$target_arch'."
    echo "Set BREW_BIN=/path/to/brew and retry."
    exit 1
fi

TOPDIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$TOPDIR"

shim_dir="/tmp/build-macos-${target_arch}"
mkdir -p "$shim_dir"

if [[ "$skip_build" != true ]]
then
    echo "==> Running native macOS build for arch=$target_arch"
    run_arch ./scripts/build-macos.sh
fi

for version in "${versions[@]}"
do
    minor="${version#3.}"

    echo "==> Preparing Python $version for arch=$target_arch"
    run_arch "$brew_bin" install "python@3.$minor"

    py_prefix="$(run_arch "$brew_bin" --prefix "python@3.$minor")"
    pybin="$py_prefix/bin/python3.$minor"
    pipbin="$py_prefix/bin/pip3.$minor"

    if [[ ! -x "$pybin" || ! -x "$pipbin" ]]
    then
        echo "Could not locate python/pip binaries under $py_prefix for $version"
        exit 1
    fi

    ln -sf "$pybin" "$shim_dir/python3"
    ln -sf "$pybin" "$shim_dir/python"
    ln -sf "$pipbin" "$shim_dir/pip3"
    ln -sf "$pipbin" "$shim_dir/pip"

    echo "==> Building wheel for Python $version (arch=$target_arch)"
    PATH="$shim_dir:$PATH" run_arch ./scripts/wheel-macos.sh "$version"

    out_dir="wheelhouse-all/$target_arch/$version"
    mkdir -p "$out_dir"
    cp wheelhouse/*.whl "$out_dir/"

done

if [[ "$run_tests" == true ]]
then
    echo "==> Downloading test data"
    curl -L http://download.ecmwf.int/test-data/magics/2m_temperature.grib -o tests/data.grib
    curl -L https://github.com/ecmwf/climetlab/raw/main/docs/examples/test.grib -o tests/climetlab.grib
    curl -L https://github.com/ecmwf/climetlab/raw/main/docs/examples/test.nc -o tests/climetlab.nc

    for version in "${versions[@]}"
    do
        echo "==> Running tests for Python $version (arch=$target_arch)"
        minor="${version#3.}"
        py_prefix="$(run_arch "$brew_bin" --prefix "python@3.$minor")"
        pybin="$py_prefix/bin/python3.$minor"

        "$pybin" -m pip install --upgrade pip
        "$pybin" -m pip install -r tests/requirements.txt
        "$pybin" -m pip install --force-reinstall "wheelhouse-all/$target_arch/$version"/*.whl

        (
            cd tests
            "$pybin" -m pytest -v -s
        )
    done
fi

echo "==> Done. Wheels are in wheelhouse-all/$target_arch"
