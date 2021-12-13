project( open_netcdf LANGUAGES C )
cmake_minimum_required(VERSION 3.21)

find_path (NETCDF_INCLUDES_C netcdf.h HINTS NETCDF_DIR NETCDF_DIR)
include_directories(${NETCDF_INCLUDES_C})

find_library (NETCDF_LIBRARIES_C  NAMES netcdf)

add_executable(open_netcdf open_netcdf.c)
target_link_libraries(open_netcdf ${NETCDF_LIBRARIES_C})
