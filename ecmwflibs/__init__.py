import os
import tempfile
import atexit
from ._ecmwflibs import versions as _versions

__version__ = '0.0.13'


_here = os.path.join(os.path.dirname(__file__))

if 'MAGPLUS_HOME' not in os.environ:
    os.environ['MAGPLUS_HOME'] = _here

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
