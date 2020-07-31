import os
import tempfile
import atexit

__version__ = '0.0.12'

here = os.path.join(os.path.dirname(__file__))

if 'MAGPLUS_HOME' not in os.environ:
    os.environ['MAGPLUS_HOME'] = here

fonts = """<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
<dir>{ecmwflibs}/share/magics/ttf</dir>
</fontconfig>""".format(ecmwflibs=here)

fontcfg = tempfile.mktemp("ecmwflibs")
with open(fontcfg, "w") as f:
    print(fonts, file=f)

os.environ['FONTCONFIG_FILE'] = fontcfg
os.environ['PROJ_LIB'] = os.path.join(here, 'share', 'proj')


def cleanup():
    try:
        os.unlink(fontcfg)
    except Exception:
        pass


atexit.register(cleanup)


def find(name):
    here = os.path.dirname(__file__)
    for libdir in [here + '.libs', os.path.join(here, '.dylibs')]:

        if not name.startswith('lib'):
            name = 'lib' + name

        if os.path.exists(libdir):
            for file in os.listdir(libdir):
                if file.endswith('.so') or file.endswith('.dylib'):
                    if name == file.split('-')[0].split('.')[0]:
                        return os.path.join(libdir, file)
