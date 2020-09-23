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
	pip install meson ninja
