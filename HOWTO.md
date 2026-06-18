# ecmwflibs

## Compiling on a Mac
### Creating the macos version of the package

Supported Python versions: 3.10 to 3.14.

First make sure you have the required packages:

```bash
brew install python3
brew install cmake
brew install pango cairo proj pkg-config
brew install netcdf ninja
pip3 install delocate wheel
```

This can be achieved by simply typing:

```bash
make tools
```

Then:

```bash
cd ~/git/ecmwflibs
make clean
make
twine upload wheelhouse/*
```

### To select a specific supported Python version, use pyenv:

```bash
brew install pyenv
brew install pyenv-virtualenv
pyenv install 3.10.16
pyenv virtualenv 3.10.16 py310

pyenv activate py310
pip3 install ninja delocate wheel
cd ~/git/ecmwflibs
make clean
make
twine upload wheelhouse/*

```

### Creating the linux version of the package

Cross compiling a Linux version on a Mac requires Docker installed.

```bash
cd ~/git/ecmwflibs
make image
make clean
./dockcross-build-ecmwflibs make
twine upload wheelhouse/*
```

You can also compile interactivaly

```bash
./dockcross-build-ecmwflibs bash
make
exit
```

### Creating *all* linux versions of the package
```bash
cd ~/git/ecmwflibs
make image
make clean
./dockcross-build-ecmwflibs make wheels.linux
twine upload wheelhouse/*
```

## Compiling on Linux

Not tried, but the docker-based solution should work.

## Local CI checks with Docker Compose

From the repository root, you can run Linux build+test flows locally:

```bash
docker compose -f docker/compose.yml run --rm linux-manylinux2014
docker compose -f docker/compose.yml run --rm linux-manylinux-2-28
```

For Linux arm64 variants:

```bash
docker compose -f docker/compose.yml run --rm linux-manylinux2014-arm64
docker compose -f docker/compose.yml run --rm linux-manylinux-2-28-arm64
```

This mirrors the split Linux strategy:
- manylinux2014 for Python 3.10-3.13 (x86_64 and arm64)
- manylinux_2_28 for Python 3.14 (x86_64 and arm64)

## Local macOS CI helper

You can run local macOS build/wheel checks with:

```bash
./scripts/ci-macos-local.sh --arch arm64
```

To include tests as well:

```bash
./scripts/ci-macos-local.sh --arch arm64 --run-tests
```

On Apple Silicon, you can also run an x86_64 pass (requires Rosetta and x86_64 Homebrew):

```bash
./scripts/ci-macos-local.sh --arch x86_64
```

If x86_64 brew is not in the default location, set it explicitly:

```bash
BREW_BIN=/usr/local/bin/brew ./scripts/ci-macos-local.sh --arch x86_64
```

### Faster local iteration (reuse existing build artifacts)

To avoid cleaning `src/`, `build/`, and `build-ecmwf/` on every run, set:

```bash
ECMWFLIBS_CLEAN=0
```

In no-clean mode, source repos are synced to the configured URL/ref by default.
If you explicitly want to reuse existing source checkouts without syncing, set:

```bash
ECMWFLIBS_SYNC_SOURCES=0
```

You can also build against a local Magics checkout (for feature branches):

```bash
ECMWFLIBS_CLEAN=0 \
GIT_MAGICS="file:///Users/maer/Repositories/magics" \
MAGICS_VERSION="feature/netcdf-proj4-matrix-interpreter" \
./scripts/build-macos.sh

./scripts/wheel-macos.sh 3.10
```

Note: cloning from `file://` uses committed Git state. Commit local changes in the Magics repo before running if you need them included.

## Windows host helper (optional)

On a Windows machine with the required toolchain (Visual Studio + vcpkg + Git Bash), you can run:

```bash
WINARCH=x64 ./scripts/ci-windows-host.sh
```

Or pass explicit Python versions:

```bash
WINARCH=x64 ./scripts/ci-windows-host.sh 3.10 3.11 3.12 3.13 3.14
```

# Usefull links

On wheels:

https://snarky.ca/the-challenges-in-designing-a-library-for-pep-425/

* https://stackoverflow.com/questions/47042483/how-to-build-and-distribute-a-python-cython-package-that-depends-on-third-party
* https://cython.readthedocs.io/en/latest/src/tutorial/cython_tutorial.html
* https://malramsay.com/post/perils_of_packaging/
* https://python-packaging-tutorial.readthedocs.io/en/latest/binaries_dependencies.html
* https://scikit-build.readthedocs.io/en/latest/
* https://stackoverflow.com/questions/24347450/how-do-you-add-additional-files-to-a-wheel


[vagrant@centos8 ~]$ pip3 install ecmwflibs
Collecting ecmwflibs
  Could not find a version that satisfies the requirement ecmwflibs (from versions: )
No matching distribution found for ecmwflibs
[vagrant@centos8 ~]$ pip3 install --upgrade pip3
Collecting pip3
  Could not find a version that satisfies the requirement pip3 (from versions: )
No matching distribution found for pip3
[vagrant@centos8 ~]$ pip3 install --upgrade pip
Collecting pip
