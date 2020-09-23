tools.linux:
	ldconfig -v | grep libcurl
	cat /etc/ld.so.conf
	yum install -y netcdf-devel netcdf-cxx-devel
	yum install -y libpng-devel
	yum install -y libtiff-devel
	yum install -y fontconfig-devel
	yum install -y flex bison
	yum install -y gobject-introspection-devel
