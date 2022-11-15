#!/usr/bin/env python3
# (C) Copyright 2020 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.
#

import atexit
import json
import os
import sys
import tempfile
import warnings

from findlibs import find as _find_library

__version__ = "0.5.0"


_here = os.path.join(os.path.dirname(__file__))
_universal = os.path.exists(os.path.join(_here, "_universal"))


if _universal:
    _versions = dict
else:
    _fonts = f"""<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
<dir>{_here}/share/magics/ttf</dir>
</fontconfig>"""

    _fontcfg = tempfile.mktemp("ecmwflibs.xml")
    with open(_fontcfg, "w") as _f:
        print(_fonts, file=_f)

    if "ECMWFLIBS_MAGPLUS" not in os.environ:

        os.environ["FONTCONFIG_FILE"] = os.environ.get(
            "ECMWFLIBS_FONTCONFIG_FILE", _fontcfg
        )
        os.environ["PROJ_LIB"] = os.environ.get(
            "ECMWFLIBS_PROJ_LIB", os.path.join(_here, "share", "proj")
        )
        os.environ["MAGPLUS_HOME"] = os.environ.get("ECMWFLIBS_MAGPLUS_HOME", _here)

    if "ECMWFLIBS_ECCODES" not in os.environ:

        for env in (
            "ECCODES_DEFINITION_PATH",
            "ECCODES_EXTRA_DEFINITION_PATH",
            "ECCODES_EXTRA_SAMPLES_PATH",
            "ECCODES_SAMPLES_PATH",
            "GRIB_DEFINITION_PATH",
            "GRIB_SAMPLES_PATH",
        ):
            if env in os.environ:
                if "ECMWFLIBS_" + env in os.environ:
                    os.environ[env] = os.environ["ECMWFLIBS_" + env]
                    warnings.warn(
                        "ecmwflibs: using provided '{}' set to '{}".format(
                            env, os.environ[env]
                        )
                    )
                else:
                    warnings.warn(
                        (
                            "ecmwflibs: ignoring provided '{}' set to '{}'. "
                            "If you want ecmwflibs to use this environment variable, use ECMWFLIBS_{} instead. "
                            "If you want to use your own ECCODES library, use ECMWFLIBS_ECCODES."
                        ).format(env, os.environ[env], env)
                    )
                    del os.environ[env]

    # This comes *after* the variables are set, so c++ has access to them
    try:
        from ._ecmwflibs import versions as _versions
    except ImportError as e:
        # ImportError: DLL load failed while importing _ecmwflibs: The specified module could not be found.
        warnings.warn(str(e))
        raise


def universal():
    return _universal


def _cleanup():
    try:
        os.unlink(_fontcfg)
    except Exception:
        pass


if not _universal:
    atexit.register(_cleanup)


_MAP = {
    "magics": "MagPlus",
    "magplus": "MagPlus",
    "grib_api": "eccodes",
    "gribapi": "eccodes",
}

EXTENSIONS = {
    "darwin": ".dylib",
    "win32": ".dll",
}


def _lookup(name):
    return _MAP.get(name, name)


def find(name):
    """Returns the path to the selected library, or None if not found."""

    name = _lookup(name)

    if int(os.environ.get("ECMWFLIBS_DISABLED", "0")):
        warnings.warn(f"ECMWFLIBS_DISABLED is set looking for {name}")
        return None

    if int(os.environ.get("ECMWFLIBS_USED_INSTALLED", "0")):
        path = _find_library(name)
        if path is None:
            warnings.warn(f"ECMWFLIBS_USED_INSTALLED did not find {name}")
        else:
            warnings.warn(f"ECMWFLIBS_USED_INSTALLED found {name} at {path}")
        return path

    if _universal:  # Universal version
        path = _find_library(name)
        if path:
            warnings.warn(f"ecmwflibs universal: found {name} at {path}")
        else:
            warnings.warn(f"ecmwflibs universal: cannot find a library called {name}")
        return path

    env = "ECMWFLIBS_" + name.upper()
    if env in os.environ:
        warnings.warn(
            "ecmwflibs: using provided '{}' set to '{}".format(env, os.environ[env])
        )
        return os.environ[env]

    here = os.path.dirname(__file__)
    extension = EXTENSIONS.get(sys.platform, ".so")

    for libdir in [here + ".libs", os.path.join(here, ".dylibs"), here]:

        if not name.startswith("lib"):
            names = ["lib" + name, name]
        else:
            names = [name, name[3:]]

        if os.path.exists(libdir):
            for file in os.listdir(libdir):
                if file.endswith(extension):
                    for name in names:
                        if name == file.split("-")[0].split(".")[0]:
                            return os.path.join(libdir, file)

    return None


def versions():
    """Returns the list of libraries and their version."""
    v = {"ecmwflibs": __version__}
    v.update(_versions())
    return v


def files():
    here = os.path.dirname(__file__)
    for root, dirs, files in os.walk(here):
        for file in files:
            yield os.path.join(root, file).replace(here, "")


def credits():
    """Displays the list of embedded libraries and their copyright
    notices and/or licenses."""
    here = os.path.dirname(__file__)
    with open(os.path.join(here, "copying/list.json")) as f:
        x = json.loads(f.read())

    for k, v in sorted(x.items()):
        print("*" * 80)
        print("name", k)
        print("home", v["home"])
        print("*" * 80)
        print()
        with open(os.path.join(here, v["path"])) as f:
            print(f.read())

    print("*" * 80)


def builds():
    here = os.path.dirname(__file__)
    with open(os.path.join(here, "versions.txt")) as f:
        for d in f.readlines():
            print(d)
