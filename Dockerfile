FROM dockcross/manylinux2014-x64:latest

# ENV DEFAULT_DOCKCROSS_IMAGE my_cool_image

RUN yum install -y netcdf-devel netcdf-cxx-devel
#RUN yum install -y jasper-devel
RUN yum install -y libpng-devel
RUN yum install -y libtiff-devel
RUN yum install -y fontconfig-devel
RUN yum install -y flex bison
# RUN yum install -y strace gdb
RUN yum install -y gobject-introspection-devel
RUN ln -s /opt/python/cp36-cp36m/bin/python /usr/local/bin/python3
RUN ln -s /opt/python/cp36-cp36m/bin/python3-config /usr/local/bin/python3-config
RUN ln -s /opt/python/cp36-cp36m/bin/pip /usr/local/bin/pip3
RUN pip3 install meson ninja auditwheel
RUN ln -s /opt/python/cp36-cp36m/bin/meson /usr/local/bin/meson
RUN ln -s /opt/python/cp36-cp36m/bin/ninja /usr/local/bin/ninja
# RUN yum install -y ack
# RUN yum install -y less
