SHELL=/bin/bash

ARCH := $(shell uname | tr '[A-Z]' '[a-z]' | sed 's/-.*//')

MAKE=ninja
MAKEFILES=Ninja


ifeq ($(ARCH), darwin)
CMAKEBIN=cmake
LIB64=lib
# This seems to be needed for py36 and py37, but not anymore from py38
CMAKE_EXTRA="-DCMAKE_INSTALL_RPATH=$(CURDIR)/install/lib"
MEMFS=1
PYTHON3 := $(shell which python3)
PIP3 := $(shell which pip3)
endif

ifeq ($(ARCH), linux)
LIB64=lib
# Make sure the right libtool is used (installing gobject-... changes libtool)
export PATH := $(CURDIR)/install/bin:/usr/bin:$(PATH):$(HOME)/.local/bin
MEMFS=1
CMAKEBIN=cmake
PYTHON3 := $(shell which python3)
PIP3 := $(shell which pip3)
# MAKE=make
# MAKEFILES="Unix Makefiles"
endif

ifeq ($(ARCH), mingw64_nt)
MEMFS=0
PYTHON3=python3
PIP3=pip
MAKE=make
MAKEFILES="Unix Makefiles"
# CMAKE_EXTRA2="-C/usr/lib/mxe/src/cmake/modules/TryRunResults.cmake"
endif

export ACLOCAL_PATH=/usr/share/aclocal
export NOCONFIGURE=1
export PKG_CONFIG_PATH=$(CURDIR)/install/lib/pkgconfig:$(CURDIR)/install/$(LIB64)/pkgconfig
export LD_LIBRARY_PATH=$(CURDIR)/install/lib:$(CURDIR)/install/$(LIB64)


target: wheel
all: all.$(ARCH)

wheel: wheel.$(ARCH)
wheels: wheels.$(ARCH)
tools: tools.$(ARCH)

#################################################################
ecbuild: src/ecbuild

src/ecbuild:
	git clone --depth 1 https://github.com/ecmwf/ecbuild.git src/ecbuild
	# We don't want that
	echo true > src/ecbuild/cmake/ecbuild_windows_replace_symlinks.sh
	chmod +x src/ecbuild/cmake/ecbuild_windows_replace_symlinks.sh

#################################################################
eccodes: ecbuild install/lib/pkgconfig/eccodes.pc

src/eccodes:
	git clone --depth 1 https://github.com/b8raoult/eccodes.git src/eccodes

#-DCMAKE_SKIP_BUILD_RPATH=1 \ -DCMAKE_BUILD_WITH_INSTALL_RPATH=1 \ -DCMAKE_INSTALL_RPATH=$(CURDIR)/lib \ -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=1 \

build-ecmwf/eccodes/build.ninja: src/eccodes
	mkdir -p build-ecmwf/eccodes
	(cd build-ecmwf/eccodes; ../../src/ecbuild/bin/ecbuild  \
		--cmakebin=$(CMAKEBIN) \
		../../src/eccodes -G$(MAKEFILES) \
		-DENABLE_PYTHON=0 \
		-DENABLE_FORTRAN=0 \
		-DENABLE_MEMFS=$(MEMFS) \
		-DENABLE_BUILD_TOOLS=0 \
		-DENABLE_INSTALL_ECCODES_DEFINITIONS=0 \
		-DENABLE_INSTALL_ECCODES_SAMPLES=0 \
		-DCMAKE_INSTALL_PREFIX=$(CURDIR)/install $(CMAKE_EXTRA) $(CMAKE_EXTRA2))


install/lib/pkgconfig/eccodes.pc: build-ecmwf/eccodes/build.ninja
	$(MAKE) -C build-ecmwf/eccodes install

#################################################################
magics-depend-darwin: eccodes

magics-depend-linux: eccodes #cairo pango proj

magics-depend-mingw64_nt: eccodes #cairo pango proj


# magics-depend-mxe: eccodes # install/lib/libeccodes.so

# install/lib/libeccodes.so: install/bin/libeccodes.dll
# 	ln -s install/bin/libeccodes.dll install/lib/libeccodes.so
# 	cp install/bin/libeccodes.dll.a install/lib/libeccodes.a

magics:  magics-depend-$(ARCH) install/lib/pkgconfig/magics.pc

src/magics:
	git clone --depth 1 https://github.com/b8raoult/magics src/magics

build-ecmwf/magics/build.ninja: src/magics
	- $(PIP3) install jinja2
	mkdir -p build-ecmwf/magics
	(cd build-ecmwf/magics; ../../src/ecbuild/bin/ecbuild  \
		--cmakebin=$(CMAKEBIN) \
		../../src/magics -G$(MAKEFILES) \
		-DPYTHON_EXECUTABLE=$(PYTHON3) \
		-DENABLE_PYTHON=0 \
		-DENABLE_FORTRAN=0 \
		-DENABLE_BUILD_TOOLS=0 \
		-Deccodes_DIR=$(CURDIR)/install/lib/cmake/eccodes \
		-DCMAKE_INSTALL_PREFIX=$(CURDIR)/install $(CMAKE_EXTRA))

install/lib/pkgconfig/magics.pc: build-ecmwf/magics/build.ninja
	$(MAKE) -C build-ecmwf/magics install
	touch install/lib/pkgconfig/magics.pc


#################################################################
# If setup.py is changed, we need to remove

.inited: setup.py ecmwflibs/__init__.py ecmwflibs/_ecmwflibs.cc
	rm -fr build
	touch .inited

#################################################################

libraries: eccodes magics

wheel.linux: .inited libraries
	rm -fr dist wheelhouse ecmwflibs/share
	cp -r install/share ecmwflibs/
	strip --strip-debug install/lib/*.so
	python3 setup.py bdist_wheel
	auditwheel repair dist/*.whl
	unzip -l wheelhouse/*.whl | grep /lib

wheel.darwin: .inited libraries
	rm -fr dist wheelhouse ecmwflibs/share
	mkdir -p install/share/magics
	cp -r install/share ecmwflibs/
	cp -r /usr/local/Cellar/proj/*/share ecmwflibs/
	strip -S install/lib/*.dylib
	$(PYTHON3) setup.py bdist_wheel
	delocate-wheel -w wheelhouse dist/*.whl
	unzip -l wheelhouse/*.whl | grep /lib


wheel.mingw64_nt: .inited libraries
	true

#################################################################

tools.darwin:
	brew install cmake ninja
	brew install pango cairo proj pkg-config boost
	brew install netcdf
	pip3 install jinja2 wheel delocate

tools.linux:
	sudo apt-get clean
	sudo apt-get update
	sudo apt-get install ninja-build  libnetcdf-dev libpango1.0-dev
	sudo apt-get install libboost-dev
	sudo apt-get install libproj-dev proj-data libopenjp2-7-dev
	sudo apt-get install python3-dev
	pip3 install wheel setuptools
	pip3 install jinja2 auditwheel


# https://repology.org/projects/?search=netcdf&inrepo=vcpkg

tools.mingw64_nt:
	vcpkg install proj
	vcpkg install netcdf-c
	vcpkg install pango


clean:
	rm -fr build install dist *.so *.whl *.egg-info wheelhouse build-ecmwf build-other src build-other

#######################
image: dockcross-build-ecmwflibs

dockcross-build-ecmwflibs: Dockerfile
	docker build -t build-ecmwflibs .
	docker run --rm dockcross/manylinux2014-x64:latest | sed 's,dockcross/manylinux2014-x64:latest,build-ecmwflibs:latest,' > dockcross-build-ecmwflibs
	chmod +x dockcross-build-ecmwflibs
