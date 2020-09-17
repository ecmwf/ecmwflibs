#!/usr/bin/env python3
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.
#

import os
import tempfile
import atexit
from ._ecmwflibs import versions as _versions

__version__ = '0.0.20'


_here = os.path.join(os.path.dirname(__file__))


_fonts = """<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
<dir>{ecmwflibs}/share/magics/ttf</dir>
</fontconfig>""".format(ecmwflibs=_here)

_fontcfg = tempfile.mktemp("ecmwflibs")
with open(_fontcfg, "w") as _f:
    print(_fonts, file=_f)

os.environ['FONTCONFIG_FILE'] = _fontcfg
os.environ['PROJ_LIB'] = os.path.join(_here, 'share', 'proj')
os.environ['MAGPLUS_HOME'] = _here

for env in (
    "ECCODES_DEFINITION_PATH",
    # "ECCODES_EXTRA_DEFINITION_PATH",
    # "ECCODES_EXTRA_SAMPLES_PATH"
    # "ECCODES_SAMPLES_PATH",
    "GRIB_DEFINITION_PATH",
    # "GRIB_SAMPLES_PATH",
):
    if env in os.environ:
        del os.environ[env]


def _cleanup():
    try:
        os.unlink(_fontcfg)
    except Exception:
        pass


atexit.register(_cleanup)


_MAP = {
    "magics": "MagPlus",
    "magplus": "MagPlus",
    "grib_api": "eccodes",
    "gribapi": "eccodes",
}


def _lookup(name):
    return _MAP.get(name, name)


def find(name):
    """Returns the path to the selected library, or None if not found."""
    name = _lookup(name)
    here = os.path.dirname(__file__)
    for libdir in [here + '.libs', os.path.join(here, '.dylibs')]:

        if not name.startswith('lib'):
            name = 'lib' + name

        if os.path.exists(libdir):
            for file in os.listdir(libdir):
                if file.endswith('.so') or file.endswith('.dylib'):
                    if name == file.split('-')[0].split('.')[0]:
                        return os.path.join(libdir, file)


def versions():
    """Returns the list of libraries and their version."""
    v = _versions()
    v["ecmwflibs"] = __version__
    return v
