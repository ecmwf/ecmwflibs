#!/usr/bin/env python3
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

include VERSIONS.make

SHELL=/bin/bash

ARCH := $(shell uname | tr '[A-Z]' '[a-z]' | sed 's/-.*//')

MAKEFILES=Ninja
MAKE=ninja

ifeq ($(ARCH), darwin)
LIB64=lib
# This seems to be needed for py36 and py37, but not anymore from py38
CMAKE_EXTRA1="-DCMAKE_INSTALL_RPATH=$(CURDIR)/install/lib"
MEMFS=1
PYTHON3 := $(shell which python3)
PIP3 := $(shell which pip3)
endif

ifeq ($(ARCH), linux)
LIB64=lib64
# Make sure the right libtool is used (installing gobject-... changes libtool)
export PATH := $(CURDIR)/install/bin:/usr/bin:$(PATH)
MEMFS=1
PYTHON3 := $(shell which python3)
PIP3 := $(shell which pip3)
endif


export ACLOCAL_PATH=/usr/share/aclocal
export NOCONFIGURE=1
export PKG_CONFIG_PATH=$(CURDIR)/install/lib/pkgconfig:$(CURDIR)/install/$(LIB64)/pkgconfig
export LD_LIBRARY_PATH=$(CURDIR)/install/lib:$(CURDIR)/install/$(LIB64):C:/vcpkg\installed\x86-windows\lib\


ifeq ($(ARCH), mingw64_nt)
MEMFS=0
# Create .lib files
CMAKE_EXTRA1="-DCMAKE_GNUtoMS=1"
# See https://docs.microsoft.com/en-us/cpp/build/vcpkg?view=vs-2019
# Use VCPKG_INSTALLATION_ROOT
# CMAKE_EXTRA2="-DCMAKE_TOOLCHAIN_FILE=c:\vcpkg\scripts\buildsystems\vcpkg.cmake"

# CMAKE_EXTRA3="-DCMAKE_C_COMPILER=cl.exe"
# c:\msys64\mingw32\bin\i686-w64-mingw32-pkg-config.exe
# c:\msys64\mingw64\bin\pkg-config.exe
# :\msys64\mingw64\bin\x86_64-w64-mingw32-pkg-config.exe
# c:\msys64\usr\bin\pkg-config.exe
# MAKEFILES="Unix Makefiles"
# MAKE=make
export PKG_CONFIG_PATH=/c/vcpkg/installed/x86-windows/lib/pkgconfig
export CMAKE_PREFIX_PATH=/c/vcpkg/installed/x86-windows
endif

# export PKG_CONFIG_PATH_i686_w64_mingw32_static=$(CURDIR)/install/lib/pkgconfig:$(CURDIR)/install/$(LIB64)/pkgconfig
# export PKG_CONFIG_PATH_i686_w64_mingw32_shared=$(CURDIR)/install/lib/pkgconfig:$(CURDIR)/install/$(LIB64)/pkgconfig

#export DYLD_LIBRARY_PATH=$(CURDIR)/install/lib
#export RPATH=$(CURDIR)/install/lib
#export DYLD_FALLBACK_LIBRARY_PATH=$(CURDIR)/install/lib

target: wheel
all: all.$(ARCH)

wheel: wheel.$(ARCH)
wheels: wheels.$(ARCH)
tools: tools.$(ARCH)
libraries: eccodes magics


all.darwin: image
	rm -fr dist wheelhouse install build-ecmwf wheelhouse.darwin wheelhouse.linux
	make wheels.darwin
	mv wheelhouse wheelhouse.darwin
	rm -fr dist wheelhouse install build-ecmwf
	./dockcross-build-ecmwflibs make wheels.linux
	mv wheelhouse wheelhouse.linux
	ls -l wheelhouse.*


#################################################################
ecbuild: src/ecbuild

src/ecbuild:
	git clone --depth 1 $(GIT_ECBUILD) src/ecbuild
	# We don't want that
	echo true > src/ecbuild/cmake/ecbuild_windows_replace_symlinks.sh
	chmod +x src/ecbuild/cmake/ecbuild_windows_replace_symlinks.sh

#################################################################
eccodes: ecbuild install/lib/pkgconfig/eccodes.pc

src/eccodes:
	git clone --depth 1 $(GIT_ECCODES) src/eccodes

build-ecmwf/eccodes/build.ninja: src/eccodes
	mkdir -p build-ecmwf/eccodes
	(cd build-ecmwf/eccodes; ../../src/ecbuild/bin/ecbuild  \
		../../src/eccodes -G$(MAKEFILES) \
		-DENABLE_PYTHON=0 \
		-DENABLE_FORTRAN=0 \
		-DENABLE_BUILD_TOOLS=0 \
		-DENABLE_MEMFS=$(MEMFS) \
		-DENABLE_INSTALL_ECCODES_DEFINITIONS=0 \
		-DENABLE_INSTALL_ECCODES_SAMPLES=0 \
		-DCMAKE_INSTALL_PREFIX=$(CURDIR)/install $(CMAKE_EXTRA1) $(CMAKE_EXTRA2) $(CMAKE_EXTRA3))


install/lib/pkgconfig/eccodes.pc: build-ecmwf/eccodes/build.ninja
	$(MAKE) -C build-ecmwf/eccodes install

#################################################################
magics-depend-darwin: eccodes

magics-depend-linux: eccodes cairo pango proj

magics-depend-mingw64_nt: eccodes

magics:  magics-depend-$(ARCH) install/lib/pkgconfig/magics.pc

src/magics:
	git clone --depth 1 $(GIT_MAGICS) src/magics
		# -DPYTHON_EXECUTABLE=$(PYTHON3)

build-ecmwf/magics/build.ninja: src/magics
	mkdir -p build-ecmwf/magics
	(cd build-ecmwf/magics; ../../src/ecbuild/bin/ecbuild  \
		--cmakebin=$(CMAKEBIN) \
		../../src/magics -G$(MAKEFILES) \
		-DENABLE_BUILD_TOOLS=0 \
		-DENABLE_PYTHON=0 \
		-DENABLE_FORTRAN=0 \
		-Deccodes_DIR=$(CURDIR)/install/lib/cmake/eccodes \
		-DCMAKE_INSTALL_PREFIX=$(CURDIR)/install $(CMAKE_EXTRA1) $(CMAKE_EXTRA2) $(CMAKE_EXTRA3))

install/lib/pkgconfig/magics.pc: build-ecmwf/magics/build.ninja
	$(MAKE) -C build-ecmwf/magics install
	touch install/lib/pkgconfig/magics.pc

#################################################################

sqlite: install/lib/pkgconfig/sqlite3.pc

src/sqlite/configure:
	git clone --depth 1 $(GIT_SQLITE) src/sqlite

src/sqlite/config.status: src/sqlite/configure
	(cd src/sqlite; \
		./configure \
		--disable-tcl \
		--prefix=$(CURDIR)/install )


install/lib/pkgconfig/sqlite3.pc: src/sqlite/config.status
	make -C src/sqlite install

#################################################################

proj: sqlite install/lib/pkgconfig/proj.pc

src/proj/autogen.sh:
	git clone --depth 1 $(GIT_PROJ) src/proj

src/proj/config.status: src/proj/autogen.sh
	(cd src/proj; ./autogen.sh ; ./configure --prefix=$(CURDIR)/install )


install/lib/pkgconfig/proj.pc: src/proj/config.status
	make -C src/proj install

#################################################################
# Pixman is needed by cairo

pixman: install/lib/pkgconfig/pixman-1.pc

src/pixman/autogen.sh:
	git clone --depth 1 $(GIT_PIXMAN) src/pixman

src/pixman/config.status: src/pixman/autogen.sh
	(cd src/pixman; ./autogen.sh ; ./configure --prefix=$(CURDIR)/install )


install/lib/pkgconfig/pixman-1.pc: src/pixman/config.status
	make -C src/pixman install


#################################################################
cairo: pixman install/lib/pkgconfig/cairo.pc

src/cairo/autogen.sh:
	git clone --depth 1 $(GIT_CAIRO) src/cairo

src/cairo/config.status: src/cairo/autogen.sh
	(cd src/cairo; ./autogen.sh; \
		./configure \
		--disable-xlib \
		--disable-xcb \
		--disable-qt \
		--disable-quartz \
		--disable-gl \
		--disable-gobject \
		--prefix=$(CURDIR)/install )

install/lib/pkgconfig/cairo.pc: src/cairo/config.status
	make -C src/cairo install
	touch install/lib/pkgconfig/cairo.pc


#################################################################
harfbuzz: cairo install/$(LIB64)/pkgconfig/harfbuzz.pc

src/harfbuzz/meson.build:
	git clone --depth 1 $(GIT_HARFBUZZ) src/harfbuzz

build-other/harfbuzz/build.ninja: src/harfbuzz/meson.build
	mkdir -p build-other/harfbuzz
	(cd src/harfbuzz; \
		meson setup --prefix=$(CURDIR)/install \
		-Dintrospection=disabled \
		-Dwrap_mode=nofallback \
		$(CURDIR)/build-other/harfbuzz )

install/$(LIB64)/pkgconfig/harfbuzz.pc: build-other/harfbuzz/build.ninja
	$(MAKE) -C build-other/harfbuzz install
	touch install/$(LIB64)/pkgconfig/harfbuzz.pc

#################################################################
fridibi: harfbuzz install/$(LIB64)/pkgconfig/fridibi.pc

src/fridibi/meson.build:
	git clone --depth 1 $(GIT_FRIBIDI) src/fridibi


build-other/fridibi/build.ninja: src/fridibi/meson.build
	mkdir -p build-other/fridibi
	(cd src/fridibi; \
		meson setup --prefix=$(CURDIR)/install \
		-Dintrospection=false \
		-Dwrap_mode=nofallback \
		-Ddocs=false \
		$(CURDIR)/build-other/fridibi )


install/$(LIB64)/pkgconfig/fridibi.pc: build-other/fridibi/build.ninja
	$(MAKE) -C build-other/fridibi install
	touch install/$(LIB64)/pkgconfig/fridibi.pc


#################################################################
pango: cairo harfbuzz fridibi install/$(LIB64)/pkgconfig/pango.pc

# Versions after 1.43.0 require versions of glib2 higher than
# the one in the dockcross image

# We undefine G_LOG_USE_STRUCTURED because otherwise we will have a
# undefined symbol g_log_structured_standard() when running on recent
# docker images with recent versions of glib
src/pango/meson.build:
	git clone $(GIT_PANGO) src/pango
	(cd src/pango; git checkout 1.43.0)
	sed 's/.*G_LOG_USE_STRUCTURED.*//' < src/pango/meson.build > src/pango/meson.build.patched
	cp src/pango/meson.build.patched src/pango/meson.build
	sed 's/.*G_LOG_USE_STRUCTURED.*//' < src/pango/pango/meson.build > src/pango/pango/meson.build.patched
	cp src/pango/pango/meson.build.patched src/pango/pango/meson.build

build-other/pango/build.ninja: src/pango/meson.build
	mkdir -p build-other/pango
	(cd src/pango; \
		meson setup --prefix=$(CURDIR)/install \
		-Dwrap_mode=nofallback \
		$(CURDIR)/build-other/pango )


install/$(LIB64)/pkgconfig/pango.pc: build-other/pango/build.ninja
	$(MAKE) -C build-other/pango install
	touch install/$(LIB64)/pkgconfig/pango.pc

#################################################################
# If setup.py is changed, we need to remove `build`

.inited: setup.py ecmwflibs/__init__.py ecmwflibs/_ecmwflibs.cc
	rm -fr build
	touch .inited

#################################################################

wheel.mingw64_nt: .inited eccodes
	rm -fr dist wheelhouse ecmwflibs/share
	# cp -r install/share ecmwflibs/
	mkdir -p install/include
	echo '#define MAGICS_VERSION_STR "none"' > install/include/magics.h
	python setup.py bdist_wheel
	# unzip -l wheelhouse/*.whl | grep /lib

wheel.linux: .inited eccodes magics
	rm -fr dist wheelhouse ecmwflibs/share
	cp -r install/share ecmwflibs/
	strip --strip-debug install/lib/*.so install/lib64/*.so
	$(PYTHON3) setup.py bdist_wheel
	auditwheel repair dist/*.whl
	unzip -l wheelhouse/*.whl | grep /lib

wheels.linux: .inited eccodes magics
	rm -fr dist wheelhouse ecmwflibs/share
	cp -r install/share ecmwflibs/
	strip --strip-debug install/lib/*.so install/lib64/*.so

	/opt/python/cp35-cp35m/bin/python3 setup.py bdist_wheel
	auditwheel repair dist/*.whl
	rm -fr dist

	/opt/python/cp36-cp36m/bin/python3 setup.py bdist_wheel
	auditwheel repair dist/*.whl
	rm -fr dist

	/opt/python/cp37-cp37m/bin/python3 setup.py bdist_wheel
	auditwheel repair dist/*.whl
	rm -fr dist

	/opt/python/cp38-cp38/bin/python3 setup.py bdist_wheel
	auditwheel repair dist/*.whl
	rm -fr dist

wheel.darwin: .inited eccodes magics
	rm -fr dist wheelhouse ecmwflibs/share
	mkdir -p install/share/magics
	cp -r install/share ecmwflibs/
	cp -r /usr/local/Cellar/proj/*/share ecmwflibs/
	strip -S install/lib/*.dylib
	$(PYTHON3) setup.py bdist_wheel
	delocate-wheel -w wheelhouse dist/*.whl
	unzip -l wheelhouse/*.whl | grep /lib


wheels.darwin: .inited pyenv-versions eccodes magics
	rm -fr dist wheelhouse ecmwflibs/share
	cp -r install/share ecmwflibs/
	cp -r /usr/local/Cellar/proj/*/share ecmwflibs/
	strip -S install/lib/*.dylib

	$(HOME)/.pyenv/versions/py35/bin/python setup.py bdist_wheel
	delocate-wheel -w wheelhouse dist/*.whl
	rm -fr dist

	$(HOME)/.pyenv/versions/py36/bin/python setup.py bdist_wheel
	delocate-wheel -w wheelhouse dist/*.whl
	rm -fr dist

	$(HOME)/.pyenv/versions/py37/bin/python setup.py bdist_wheel
	delocate-wheel -w wheelhouse dist/*.whl
	rm -fr dist

	$(HOME)/.pyenv/versions/py38/bin/python setup.py bdist_wheel
	delocate-wheel -w wheelhouse dist/*.whl
	rm -fr dist


pyenv-versions: $(HOME)/.pyenv/versions/py35/bin/python \
                $(HOME)/.pyenv/versions/py36/bin/python \
                $(HOME)/.pyenv/versions/py37/bin/python \
                $(HOME)/.pyenv/versions/py38/bin/python


$(HOME)/.pyenv/versions/py35/bin/python:
	pyenv install 3.5.9
	pyenv virtualenv 3.5.9 py35
	$(HOME)/.pyenv/versions/py35/bin/pip install wheel jinja2

$(HOME)/.pyenv/versions/py36/bin/python:
	pyenv install 3.6.10
	pyenv virtualenv 3.6.10 py36
	$(HOME)/.pyenv/versions/py36/bin/pip install wheel jinja2

$(HOME)/.pyenv/versions/py37/bin/python:
	pyenv install 3.7.7
	pyenv virtualenv 3.7.7 py37
	$(HOME)/.pyenv/versions/py37/bin/pip install wheel jinja2

$(HOME)/.pyenv/versions/py38/bin/python:
	pyenv install 3.8.3
	pyenv virtualenv 3.8.3 py38
	$(HOME)/.pyenv/versions/py38/bin/pip install wheel jinja2

tools.darwin:
	- brew install python3
	- brew install pyenv pyenv-virtualenv
	- brew install cmake ninja
	- brew install pango cairo proj pkg-config boost
	- brew install netcdf
	- pip3 install jinja2 wheel delocate

tools.linux:
	true

tools.mingw64_nt:
	vcpkg install proj
	# vcpkg install netcdf-c
	vcpkg install pango
	pip install ninja
	pip install jinja2 wheel


clean:
	rm -fr build install dist *.so *.whl *.egg-info wheelhouse build-ecmwf build-other src build-other


image: dockcross-build-ecmwflibs

dockcross-build-ecmwflibs: Dockerfile
	docker build -t build-ecmwflibs .
	docker run --rm dockcross/manylinux2014-x64:latest | sed 's,dockcross/manylinux2014-x64:latest,build-ecmwflibs:latest,' > dockcross-build-ecmwflibs
	chmod +x dockcross-build-ecmwflibs
