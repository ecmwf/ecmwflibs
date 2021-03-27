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
import ctypes
import json
import os
import sys
import tempfile


__version__ = "0.2.3"


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

    _fontcfg = tempfile.mktemp("ecmwflibs")
    with open(_fontcfg, "w") as _f:
        print(_fonts, file=_f)

    if "ECMWFLIBS_MAGPUS" not in os.environ:

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
                del os.environ[env]
                if "ECMWFLIBS_" + env in os.environ:
                    os.environ[env] = os.environ["ECMWFLIBS_" + env]
                    print(
                        "ecmwflibs: using provided '{}' set to '{}".format(
                            env, os.environ[env]
                        ),
                        file=sys.stderr,
                    )

    # This comes *after* the variables are set, so c++ has access to them
    from ._ecmwflibs import versions as _versions


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
        print(f"ECMWFLIBS_DISABLED is set looking for {name}", file=sys.stderr)
        return None

    if int(os.environ.get("ECMWFLIBS_USED_INSTALLED", "0")):
        path = _find_library(name)
        if path is None:
            print(
                f"WARNING: ECMWFLIBS_USED_INSTALLED did not find {name}",
                file=sys.stderr,
            )
        else:
            print(
                f"WARNING: ECMWFLIBS_USED_INSTALLED found {name} at {path}",
                file=sys.stderr,
            )
        return path

    if _universal:  # Universal version
        path = _find_library(name)
        if path:
            print(
                f"WARNING: ecmwflibs universal: found {name} at {path}",
                file=sys.stderr,
            )
        else:
            print(
                f"WARNING: ecmwflibs universal: cannot find a library called {name}",
                file=sys.stderr,
            )
        return path

    env = "ECMWFLIBS_" + name.upper()
    if env in os.environ:
        print(
            "ecmwflibs: using provided '{}' set to '{}".format(env, os.environ[env]),
            file=sys.stderr,
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


def _find_library(name):

    extension = EXTENSIONS.get(sys.platform, ".so")

    LIB_HOME = "{}_HOME".format(name.upper())
    if LIB_HOME in os.environ:
        home = os.environ[LIB_HOME]
        fullname = os.path.join(home, "lib", f"lib{name}{extension}")
        if os.path.exists(fullname):
            return fullname

    for path in (
        "LD_LIBRARY_PATH",
        "DYLD_LIBRARY_PATH",
    ):
        for home in os.environ.get(path, "").split(":"):
            fullname = os.path.join(home, f"lib{name}{extension}")
            if os.path.exists(fullname):
                return fullname

    for root in ("/", "/usr/", "/usr/local/", "/opt/"):
        for lib in ("lib", "lib64"):
            fullname = os.path.join(home, f"{root}{lib}/lib{name}{extension}")
            if os.path.exists(fullname):
                return fullname

    return ctypes.util.find_library(name)
