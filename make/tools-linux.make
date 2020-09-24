
tools.linux:
	# There are two copies of libcurl, this confuses yum
	rm /usr/local/lib/libcurl.*
	ldconfig
	yum install -y netcdf-devel netcdf-cxx-devel
	yum install -y libpng-devel
	yum install -y libtiff-devel
	yum install -y fontconfig-devel
	yum install -y gobject-introspection-devel
	yum install -y libjasper-devel
	yum install -y flex bison
	ln -s /opt/python/cp36-cp36m/bin/python /usr/local/bin/python3
	ln -s /opt/python/cp36-cp36m/bin/python3-config /usr/local/bin/python3-config
	ln -s /opt/python/cp36-cp36m/bin/pip /usr/local/bin/pip3
	pip3 install ninja auditwheel meson
	ln -s /opt/python/cp36-cp36m/bin/meson /usr/local/bin/meson
	ln -s /opt/python/cp36-cp36m/bin/ninja /usr/local/bin/ninja

tools.linux-no:
	# There are two copies of libcurl, this confuses yum
	# rm /usr/local/lib/libcurl.*
	# ldconfig
	yum install -y netcdf-devel netcdf-cxx-devel
	yum install -y libpng-devel
	yum install -y libtiff-devel
	yum install -y fontconfig-devel
	yum install -y flex bison cmake3
	# yum install -y gobject-introspection-devel
	yum install -y pango-devel cairo-devel
	yum install -y libpng-devel libjasper-devel
	yum install -y python-devel

	# For proj70 on centos7
	yum-config-manager --add-repo 'https://download.postgresql.org/pub/repos/yum/common/redhat/rhel-$$releasever-$$basearch'

	yum install --nogpgcheck -y proj71-devel


	pip3 install ninja auditwheel
	# ln -s /opt/python/cp36-cp36m/bin/meson /usr/local/bin/meson
	# ln -s /opt/python/cp36-cp36m/bin/ninja /usr/local/bin/ninja
	ln -sf /usr/bin/cmake3 /usr/bin/cmake
	ln -s /opt/python/cp36-cp36m/bin/python /usr/local/bin/python3
	ln -s /opt/python/cp36-cp36m/bin/python3-config /usr/local/bin/python3-config
	ln -s /opt/python/cp36-cp36m/bin/pip /usr/local/bin/pip3
