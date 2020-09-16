SHELL=/bin/bash

ARCH := $(shell uname | tr '[A-Z]' '[a-z]')
PYTHON3 := $(shell which python3)
PIP3 := $(shell which pip3)


ifeq ($(ARCH), darwin)
CMAKEBIN=cmake
LIB64=lib
# This seems to be needed for py36 and py37, but not anymore from py38
CMAKE_EXTRA="-DCMAKE_INSTALL_RPATH=$(CURDIR)/install/lib"
MEMFS=1
endif

ifeq ($(ARCH), linux)
LIB64=lib64
# Make sure the right libtool is used (installing gobject-... changes libtool)
export PATH := $(CURDIR)/install/bin:/usr/bin:$(PATH)
MEMFS=1
CMAKEBIN=cmake
endif

ifeq ($(ARCH), mxe)
MEMFS=0
CMAKEBIN=/usr/lib/mxe/usr/bin/i686-w64-mingw32.shared-cmake
CMAKE_EXTRA="-C/work/docker/TryRunResults-mxe.cmake"
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
		../../src/eccodes -GNinja \
		-DENABLE_PYTHON=0 \
		-DENABLE_FORTRAN=0 \
		-DENABLE_MEMFS=$(MEMFS) \
		-DENABLE_INSTALL_ECCODES_DEFINITIONS=0 \
		-DENABLE_INSTALL_ECCODES_SAMPLES=0 \
		-DCMAKE_INSTALL_PREFIX=$(CURDIR)/install $(CMAKE_EXTRA) $(CMAKE_EXTRA2))


install/lib/pkgconfig/eccodes.pc: build-ecmwf/eccodes/build.ninja
	ninja -C build-ecmwf/eccodes install

#################################################################
magics-depend-darwin: eccodes

magics-depend-linux: eccodes #cairo pango proj

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
		../../src/magics -GNinja \
		-DPYTHON_EXECUTABLE=$(PYTHON3) \
		-DENABLE_PYTHON=0 \
		-DENABLE_FORTRAN=0 \
		-Deccodes_DIR=$(CURDIR)/install/lib/cmake/eccodes \
		-DCMAKE_INSTALL_PREFIX=$(CURDIR)/install $(CMAKE_EXTRA))

install/lib/pkgconfig/magics.pc: build-ecmwf/magics/build.ninja
	ninja -C build-ecmwf/magics install
	touch install/lib/pkgconfig/magics.pc

#################################################################

sqlite: install/lib/pkgconfig/sqlite3.pc

src/sqlite/configure:
	git clone --depth 1 https://github.com/sqlite/sqlite.git src/sqlite

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
	git clone --depth 1 https://github.com/OSGeo/PROJ.git src/proj

src/proj/config.status: src/proj/autogen.sh
	(cd src/proj; ./autogen.sh ; ./configure --prefix=$(CURDIR)/install )


install/lib/pkgconfig/proj.pc: src/proj/config.status
	make -C src/proj install

#################################################################
# Pixman is needed by cairo

pixman: install/lib/pkgconfig/pixman-1.pc

src/pixman/autogen.sh:
	git clone --depth 1 https://github.com/freedesktop/pixman src/pixman

src/pixman/config.status: src/pixman/autogen.sh
	(cd src/pixman; ./autogen.sh ; ./configure --prefix=$(CURDIR)/install )


install/lib/pkgconfig/pixman-1.pc: src/pixman/config.status
	make -C src/pixman install


#################################################################
cairo: pixman install/lib/pkgconfig/cairo.pc

src/cairo/autogen.sh:
	git clone --depth 1 https://github.com/freedesktop/cairo src/cairo

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
	git clone --depth 1 https://github.com/harfbuzz/harfbuzz.git src/harfbuzz

# 		-Dglib=disabled
#		-Dgobject=disabled

build-other/harfbuzz/build.ninja: src/harfbuzz/meson.build
	mkdir -p build-other/harfbuzz
	(cd src/harfbuzz; \
		meson setup --prefix=$(CURDIR)/install \
		-Dintrospection=disabled \
		-Dwrap_mode=nofallback \
		$(CURDIR)/build-other/harfbuzz )

install/$(LIB64)/pkgconfig/harfbuzz.pc: build-other/harfbuzz/build.ninja
	ninja -C build-other/harfbuzz install
	touch install/$(LIB64)/pkgconfig/harfbuzz.pc

#################################################################
fridibi: harfbuzz install/$(LIB64)/pkgconfig/fridibi.pc

src/fridibi/meson.build:
	git clone --depth 1 https://github.com/fribidi/fribidi.git src/fridibi


build-other/fridibi/build.ninja: src/fridibi/meson.build
	mkdir -p build-other/fridibi
	(cd src/fridibi; \
		meson setup --prefix=$(CURDIR)/install \
		-Dintrospection=false \
		-Dwrap_mode=nofallback \
		-Ddocs=false \
		$(CURDIR)/build-other/fridibi )


install/$(LIB64)/pkgconfig/fridibi.pc: build-other/fridibi/build.ninja
	ninja -C build-other/fridibi install
	touch install/$(LIB64)/pkgconfig/fridibi.pc


#################################################################
pango: cairo harfbuzz fridibi install/$(LIB64)/pkgconfig/pango.pc

# Versions after 1.43.0 require versions of glib2 higher than
# the one in the dockcross image

# We undefine G_LOG_USE_STRUCTURED because otherwise we will have a
# undefined symbol g_log_structured_standard() when renning on recent
# docker images with recent versions of glib
src/pango/meson.build:
	git clone https://gitlab.gnome.org/GNOME/pango.git src/pango
	(cd src/pango; git checkout 1.43.0)
	sed 's/.*G_LOG_USE_STRUCTURED.*//' < src/pango/meson.build > src/pango/meson.build.patched
	cp src/pango/meson.build.patched src/pango/meson.build
	sed 's/.*G_LOG_USE_STRUCTURED.*//' < src/pango/pango/meson.build > src/pango/pango/meson.build.patched
	cp src/pango/pango/meson.build.patched src/pango/pango/meson.build

# 		-Dintrospection=false \

build-other/pango/build.ninja: src/pango/meson.build
	mkdir -p build-other/pango
	(cd src/pango; \
		meson setup --prefix=$(CURDIR)/install \
		-Dwrap_mode=nofallback \
		$(CURDIR)/build-other/pango )


install/$(LIB64)/pkgconfig/pango.pc: build-other/pango/build.ninja
	ninja -C build-other/pango install
	touch install/$(LIB64)/pkgconfig/pango.pc

#################################################################
# If setup.py is changed, we need to remove

.inited: setup.py ecmwflibs/__init__.py ecmwflibs/_ecmwflibs.cc
	rm -fr build
	touch .inited

#################################################################


wheel.linux: .inited eccodes magics
	rm -fr dist wheelhouse ecmwflibs/share
	cp -r install/share ecmwflibs/
	strip --strip-debug install/lib/*.so install/lib64/*.so
	$(PYTHON3) setup.py bdist_wheel
	auditwheel repair dist/*.whl
	unzip -l wheelhouse/*.whl | grep /lib

wheel.darwin: .inited eccodes magics
	rm -fr dist wheelhouse ecmwflibs/share
	mkdir -p install/share/magics
	cp -r install/share ecmwflibs/
	cp -r /usr/local/Cellar/proj/*/share ecmwflibs/
	strip -S install/lib/*.dylib
	$(PYTHON3) setup.py bdist_wheel
	delocate-wheel -w wheelhouse dist/*.whl
	unzip -l wheelhouse/*.whl | grep /lib



tools.darwin:
	# - brew install python3
	# - brew install pyenv pyenv-virtualenv
	brew install cmake ninja
	brew install pango cairo proj pkg-config boost
	brew install netcdf
	pip install jinja2 wheel delocate

tools.linux:
	sudo apt-get update -y
	sudo apt-get install ninja-build  libnetcdf-dev libpango1.0-dev
	sudo apt-get install libboost-dev
	sudo apt-get install libproj-dev proj-bin libproj9
	pip3 install setuptools
	pip3 install jinja2 wheel auditwheel
	apt list --installed
	find /usr /opt -name proj.h

clean:
	rm -fr build install dist *.so *.whl *.egg-info wheelhouse build-ecmwf build-other src build-other
