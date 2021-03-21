#!/usr/bin/env python
import requests
import sys
import json
from html2text import html2text


def identity(x):
    return x

ENTRIES = {
    "libMagPlus": None,
    "libeccodes_memfs": None,
    "libeccodes": None,
    "libnetcdf": {
        "home": "https://github.com/Unidata/netcdf-c",
        "copying": "https://raw.githubusercontent.com/Unidata/netcdf-c/master/COPYRIGHT",
    },
    "libproj": {
        "home": "https://github.com/OSGeo/PROJ",
        "copying": "https://raw.githubusercontent.com/OSGeo/PROJ/master/COPYING",
    },
    "libpixman": {
        "home": "https://github.com/freedesktop/pixman",
        "copying": "https://raw.githubusercontent.com/freedesktop/pixman/master/COPYING",
    },
    "libfribidi": {
        "home": "https://github.com/fribidi/fribidi",
        "copying": "https://raw.githubusercontent.com/fribidi/fribidi/master/COPYING",
    },
    "libharfbuzz": {
        "home": "https://github.com/fribidi/fribidi",
        "copying": "https://raw.githubusercontent.com/fribidi/fribidi/master/COPYING",
    },
    "libuuid": {
        "home": "https://github.com/karelzak/util-linux/tree/master/libuuid",
        "copying": "https://raw.githubusercontent.com/karelzak/util-linux/master/libuuid/COPYING",
    },
    "libpango": {
        "home": "https://github.com/GNOME/pango",
        "copying": "https://raw.githubusercontent.com/GNOME/pango/master/COPYING",
    },
    "libpangoft2": None,  # Assumed to be part of libpango
    "libpangocairo": None,  # Assumed to be part of libpango
    "libsqlite3": {
        "home": "https://sqlite.org/index.html",
        "copying": "Public Domain, see https://sqlite.org/copyright.html",
    },
    "libfontconfig": {
        "home": "https://gitlab.freedesktop.org/fontconfig/fontconfig",
        "copying": "https://gitlab.freedesktop.org/fontconfig/fontconfig/-/raw/master/COPYING",
    },
    "libbz2": {
        "home": "https://gitlab.com/federicomenaquintero/bzip2",
        "copying": "https://gitlab.com/federicomenaquintero/bzip2/-/raw/master/COPYING",
    },
    "libhdf5": {
        "home": "https://github.com/HDFGroup/hdf5",
        "copying": "https://raw.githubusercontent.com/HDFGroup/hdf5/develop/COPYING",
    },
    "libhdf5_hl": None,  # Assumed to be part of libhdf5
    "libpng15": {
        "home": "https://github.com/glennrp/libpng",
        "copying": "https://raw.githubusercontent.com/glennrp/libpng/libpng16/LICENSE",
    },
    "libaec": {
        "home": "https://github.com/erget/libaec",
        "copying": "https://raw.githubusercontent.com/erget/libaec/cmake-install-instructions/COPYING",
    },
    "libexpat": {
        "home": "https://libexpat.github.io",
        "copying": "https://raw.githubusercontent.com/libexpat/libexpat/master/expat/COPYING",
    },
    "libz": {
        "home": "https://zlib.net",
        "copying": "https://zlib.net/zlib_license.html",
        "html": True,
    },
    "libcairo": {
        "home": "https://cairographics.org",
        "copying": "https://raw.githubusercontent.com/freedesktop/cairo/master/COPYING",
    },
    "libjasper": {
        "home": "https://github.com/jasper-software/jasper",
        "copying": "https://raw.githubusercontent.com/jasper-software/jasper/master/LICENSE",
    },
    "libjpeg": {
        "home": "http://ijg.org",
        "copying": "https://jpegclub.org/reference/libjpeg-license/",
        "html": True,
    },
    "libsz": {
        "home": "https://support.hdfgroup.org/doc_resource/SZIP/",
        "copying": "https://support.hdfgroup.org/doc_resource/SZIP/Commercial_szip.html",
        "html": True,
    },
    "libfreetype": {
        "home": "https://gitlab.freedesktop.org/freetype/freetype/",
        "copying": "https://gitlab.freedesktop.org/freetype/freetype/-/raw/master/docs/FTL.TXT",
    },
}

libs = {}
missing = []

for line in open(sys.argv[1], "r"):
    lib = "-no-regex-"
    line = line.strip().split()[-1].split('/')[-1]
    lib = line.split('-')[0].split('.')[0]

    if lib not in ENTRIES:
        missing.append((lib, line))
        continue

    e = ENTRIES[lib]
    if e is None:
        continue

    libs[lib] = dict(path=f"copying/{lib}.txt", home=e["home"])
    copying = e["copying"]

    filtering = identity
    if e.get("html"):
        filtering = html2text

    with open(f"ecmwflibs/copying/{lib}.txt", "w") as f:
        if copying.startswith("http://") or copying.startswith("https://"):

            r = requests.get(copying)
            r.raise_for_status()
            for n in filtering(r.text).split("\n"):
                print(n, file=f)
        else:
            for n in copying.split("\n"):
                print(n, file=f)

    with open("ecmwflibs/copying/list.json", "w") as f:
        print(json.dumps(libs), file=f)


assert len(missing) == 0, missing
