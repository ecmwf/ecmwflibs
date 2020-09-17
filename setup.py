#!/usr/bin/env python3
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.
#


import io
import os.path

from setuptools import setup, Extension, find_packages


def read(fname):
    file_path = os.path.join(os.path.dirname(__file__), fname)
    return io.open(file_path, encoding="utf-8").read()


version = None
for line in read("ecmwflibs/__init__.py").split("\n"):
    if line.startswith("__version__"):
        version = line.split("=")[-1].strip()[1:-1]

libdir = os.path.realpath("install/lib")
incdir = os.path.realpath("install/include")

# https://docs.python.org/3/distutils/apiref.html
ext_modules = [
    Extension(
        "ecmwflibs._ecmwflibs",
        sources=["ecmwflibs/_ecmwflibs.cc"],
        language="c++",
        libraries=["eccodes", "MagPlus"],
        #              libraries=['eccodes', 'eccodes_memfs', 'MagPlus'],  # Unix-like specific
        library_dirs=[libdir],
        include_dirs=[incdir, os.path.join(incdir, "magics")],
        #              runtime_library_dirs=[libdir],
        extra_link_args=["-Wl,-rpath," + libdir],
    )
]


def shared(directory):
    result = []
    for (path, dirs, files) in os.walk(directory):
        for f in files:
            result.append(os.path.join(path, f))
    return result


# Paths must be relative to package directory...
shared_files = []
shared_files += [x[len("install/") :] for x in shared("install/share/magics")]
shared_files += [x[len("ecmwflibs/") :] for x in shared("ecmwflibs/share/proj")]
shared_files += [x[len("ecmwflibs/") :] for x in shared("ecmwflibs/etc")]

# print(shared_files)

setup(
    name="ecmwflibs",
    version=version,
    author="ECMWF",
    author_email="software.support@ecmwf.int",
    license="Apache 2.0",
    url="https://github.com/ecmwf/ecmwflibs",
    description="Wraps ECMWF tools (experimental)",
    long_description=read("README.md"),
    long_description_content_type="text/markdown",
    packages=find_packages(),
    include_package_data=True,
    package_data={"": shared_files},
    install_requires=[
        # 'numpy',
    ],
    zip_safe=True,
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.4",
        "Programming Language :: Python :: 3.5",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: Implementation :: CPython",
        "Programming Language :: Python :: Implementation :: PyPy",
        "Operating System :: OS Independent",
    ],
    #    cmdclass={'build_ext': ecmwflibs_build_ext},
    ext_modules=ext_modules,
)
