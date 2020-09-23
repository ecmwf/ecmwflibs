tools.linux:
	rm /lib64/libcurl.so.4 # There are two copies!!!
	ldconfig -v | grep libcurl
	yum install -y netcdf-devel netcdf-cxx-devel
	yum install -y libpng-devel
	yum install -y libtiff-devel
	yum install -y fontconfig-devel
	yum install -y flex bison
	yum install -y gobject-introspection-devel
