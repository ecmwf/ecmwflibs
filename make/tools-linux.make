tools.linux:
	# There are two copies of libcurl, this confuses yum
	rm /usr/local/lib/libcurl.*
	ldconfig
	yum install -y netcdf-devel netcdf-cxx-devel
	yum install -y libpng-devel
	yum install -y libtiff-devel
	yum install -y fontconfig-devel
	yum install -y flex bison
	yum install -y gobject-introspection-devel
	ln -s /opt/python/cp36-cp36m/bin/python /usr/local/bin/python3
	ln -s /opt/python/cp36-cp36m/bin/python3-config /usr/local/bin/python3-config
	ln -s /opt/python/cp36-cp36m/bin/pip /usr/local/bin/pip3
	pip3 install meson ninja auditwheel
	ln -s /opt/python/cp36-cp36m/bin/meson /usr/local/bin/meson
	ln -s /opt/python/cp36-cp36m/bin/ninja /usr/local/bin/ninja
