#!/usr/bin/env python
import json
import os
import re
import socket
import time
import sys

import urllib.error
import urllib.request
try:
    from html2text import html2text
except ImportError:
    html2text = None


def identity(x):
    return x


_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux x86_64; rv:125.0) Gecko/20100101 Firefox/125.0"
    ),
    "Accept": "text/html,text/plain,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
}


def _local_fallback_path(url):
    base = os.path.basename(url.rstrip("/"))
    if not base:
        return None

    licenses_dir = os.path.join(os.path.dirname(__file__), "licenses")
    for candidate in (base, base.lower()):
        path = os.path.join(licenses_dir, candidate)
        if os.path.exists(path):
            return path
    return None


def fetch_url_text(url, lib_name, timeout=30, attempts=3):
    errors = []

    for attempt in range(1, attempts + 1):
        try:
            req = urllib.request.Request(url, headers=_HEADERS)
            with urllib.request.urlopen(req, timeout=timeout) as response:
                return response.read().decode("utf-8")
        except urllib.error.HTTPError as error:
            body_preview = error.read().decode("utf-8", errors="replace").strip()
            if len(body_preview) > 500:
                body_preview = f"{body_preview[:500]}..."
            details = [
                f"URL: {url}",
                f"Attempt: {attempt}/{attempts}",
                f"HTTP status: {error.code}",
                f"Reason: {error.reason}",
            ]
            if body_preview:
                details.append(f"Response body (first 500 chars):\n{body_preview}")
            errors.append("\n".join(details))
        except (urllib.error.URLError, TimeoutError, socket.timeout, OSError) as error:
            reason = getattr(error, "reason", str(error))
            errors.append(
                f"URL: {url}\n"
                f"Attempt: {attempt}/{attempts}\n"
                f"Network error: {reason}"
            )

        if attempt < attempts:
            time.sleep(attempt)

    fallback_path = _local_fallback_path(url)
    if fallback_path:
        with open(fallback_path, "r", encoding="utf-8") as fallback_file:
            return fallback_file.read()

    raise RuntimeError(
        f"Failed to download license for {lib_name}.\n"
        + "\n\n---\n\n".join(errors)
    )


ENTRIES = {
    "libMagPlus": {
        "home": "https://github.com/ecmwf/magics",
        "copying": "https://raw.githubusercontent.com/ecmwf/magics/develop/LICENSE",
    },
    "libeccodes": {
        "home": "https://github.com/ecmwf/eccodes",
        "copying": "https://raw.githubusercontent.com/ecmwf/eccodes/develop/LICENSE",
    },
    "libnetcdf": {
        "home": "https://github.com/Unidata/netcdf-c",
        "copying": "https://raw.githubusercontent.com/Unidata/netcdf-c/master/COPYRIGHT",
    },
    "libproj": {
        "home": "https://github.com/OSGeo/PROJ",
        "copying": "https://raw.githubusercontent.com/OSGeo/PROJ/master/COPYING",
    },
    "libpixman": {
        "home": "https://gitlab.freedesktop.org/pixman/pixman",
        "copying": "https://gitlab.freedesktop.org/pixman/pixman/-/raw/master/COPYING",
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
    "libsqlite3": {
        "home": "https://sqlite.org/index.html",
        "copying": "Public Domain, see https://sqlite.org/copyright.html",
    },
    "libfontconfig": {
        "home": "https://gitlab.freedesktop.org/fontconfig/fontconfig",
        "copying": "https://gitlab.freedesktop.org/fontconfig/fontconfig/-/raw/main/COPYING",
    },
    "libbz2": {
        "home": "https://gitlab.com/federicomenaquintero/bzip2",
        "copying": "https://gitlab.com/federicomenaquintero/bzip2/-/raw/master/COPYING",
    },
    "libhdf5": {
        "home": "https://github.com/HDFGroup/hdf5",
        "copying": "https://raw.githubusercontent.com/HDFGroup/hdf5/develop/LICENSE",
    },
    "libhdf5_hl": None,  # Assumed to be part of libhdf5 (hl = high level)
    "libpng": {
        "home": "https://github.com/glennrp/libpng",
        "copying": "https://raw.githubusercontent.com/glennrp/libpng/libpng16/LICENSE",
    },
    "libaec": {
        "home": "https://github.com/MathisRosenhauer/libaec",
        "copying": "https://raw.githubusercontent.com/MathisRosenhauer/libaec/v1.1.3/LICENSE.txt",
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
        "copying": "https://gitlab.freedesktop.org/cairo/cairo/-/raw/master/COPYING",
    },
    "libjasper": {
        "home": "https://github.com/jasper-software/jasper",
        "copying": "https://raw.githubusercontent.com/jasper-software/jasper/master/LICENSE.txt",
    },
    "libopenjp2": {
        "home": "https://github.com/uclouvain/openjpeg",
        "copying": "https://raw.githubusercontent.com/uclouvain/openjpeg/master/LICENSE",
    },
    # We build libjpeg-turbo from source (drop-in replacement, installs as libjpeg.so.62)
    "libjpeg": {
        "home": "https://github.com/libjpeg-turbo/libjpeg-turbo",
        "copying": "https://raw.githubusercontent.com/libjpeg-turbo/libjpeg-turbo/main/LICENSE.md",
    },
    "libfreetype": {
        "home": "https://gitlab.freedesktop.org/freetype/freetype/",
        "copying": "https://gitlab.freedesktop.org/freetype/freetype/-/raw/master/docs/FTL.TXT",
    },
    "libdatrie": {
        "home": "https://github.com/tlwg/libdatrie",
        "copying": "https://raw.githubusercontent.com/tlwg/libdatrie/master/COPYING",
    },
    "libthai": {
        "home": "https://github.com/tlwg/libthai",
        "copying": "https://raw.githubusercontent.com/tlwg/libthai/master/COPYING",
    },
    "libX11": {
        "home": "https://github.com/mirror/libX11",
        "copying": "https://raw.githubusercontent.com/mirror/libX11/master/COPYING",
    },
    "libxcb": {
        "home": "https://github.com/corngood/libxcb",
        "copying": "https://raw.githubusercontent.com/corngood/libxcb/master/COPYING",
    },
    "libpcre": {
        "home": "https://github.com/vmg/libpcre",
        "copying": "https://raw.githubusercontent.com/vmg/libpcre/master/LICENCE",
    },
    "libgraphite2": {
        "home": "https://github.com/silnrsi/graphite",
        "copying": "https://raw.githubusercontent.com/silnrsi/graphite/master/COPYING",
    },
    "libffi": {
        "home": "https://github.com/libffi/libffi",
        "copying": "https://raw.githubusercontent.com/libffi/libffi/master/LICENSE",
    },
    "libtiff": {
        "home": "https://gitlab.com/libtiff/libtiff",
        "copying": "https://gitlab.com/libtiff/libtiff/-/raw/master/LICENSE.md",
    },
    # See also https://www.gnu.org/software/gettext/manual/html_node/Discussions.html
    # intl(gettext) is GPL while libintl is LGPL
    "libintl": {
        "home": "https://www.gnu.org/software/gettext/manual/html_node/Licenses.html",
        "copying": "https://www.gnu.org/licenses/lgpl-3.0.txt",
        "html": True,
    },
    # See also https://www.gnu.org/software/libiconv/
    # iconv is GPL while libiconv is LGPL
    "libiconv": {
        "home": "https://www.gnu.org/software/libiconv/",
        "copying": "https://www.gnu.org/licenses/lgpl-3.0.txt",
    },
    "libglib": {
        "home": "https://gitlab.gnome.org/GNOME/glib",
        "copying": "https://gitlab.gnome.org/GNOME/glib/-/raw/main/COPYING",
    },
    "libbrotli": {
        "home": "https://github.com/google/brotli",
        "copying": "https://raw.githubusercontent.com/google/brotli/master/LICENSE",
    },
    "libpcre2": {
        "home": "https://github.com/PCRE2Project/pcre2",
        "copying": "https://raw.githubusercontent.com/PCRE2Project/pcre2/main/LICENCE.md",
    },
    "libzstd": {
        "home": "https://github.com/facebook/zstd",
        "copying": "https://raw.githubusercontent.com/facebook/zstd/master/LICENSE",
    },
    # not completely clear what the definitive source for this library is
    "liblzma": {
        "home": "https://github.com/ShiftMediaProject/liblzma",
        "copying": "https://raw.githubusercontent.com/ShiftMediaProject/liblzma/master/COPYING",
    },
    "libcurl": {
        "home": "https://github.com/curl/curl",
        "copying": "https://raw.githubusercontent.com/curl/curl/master/COPYING",
    },
    "libtinyxml2": {
        "home": "https://github.com/leethomason/tinyxml2",
        "copying": "https://raw.githubusercontent.com/leethomason/tinyxml2/master/LICENSE.txt",
    },
}

PATTERNS = {
    r"^libpng\d+$": "libpng",
    r"^libproj(_\d+)+$": "libproj",
}

ALIASES = {
    "libbrotlicommon": "libbrotli",
    "libbrotlidec": "libbrotli",
    "libpangowin32": "libpango",
    "libzlib1": "libz",
    "libeccodes_memfs": "libeccodes",
    "libgobject": "libglib",  # Part of libglib
    "libgmodule": "libglib",  # Part of libglib
    "libgio": "libglib",  # Part of libglib
    "libpangoft2": "libpango",  # Assumed to be part of libpango
    "libpangocairo": "libpango",  # Assumed to be part of libpango
    "libhdf5_hl": "libhdf5",
    # Legacy HDF SZIP license pages were retired; map to libaec.
    "libsz": "libaec",
    "libszip": "libaec",
    # X.Org stack libraries shipped transitively with cairo/pango.
    "libXrender": "libX11",
    "libXdmcp": "libX11",
    "libXau": "libX11",
    "libXext": "libX11",
}

if False:
    for e in ENTRIES.values():
        if isinstance(e, dict):
            copying = e["copying"]
            if copying.startswith("http"):
                urllib.request.urlopen(copying).close()

libs = {}
missing = []
seen = set()

for line in open(sys.argv[1], "r", encoding="utf-8"):
    lib = "-no-regex-"
    lib = line.strip().split("/")[-1]
    lib = lib.split("-")[0].split(".")[0]

    if lib == "":
        continue

    if not lib.startswith("lib"):
        lib = f"lib{lib}"

    for k, v in PATTERNS.items():
        if re.match(k, lib):
            lib = v

    lib = ALIASES.get(lib, lib)

    if lib not in ENTRIES:
        missing.append((lib, line))
        continue

    if lib in seen:
        continue

    seen.add(lib)

    e = ENTRIES[lib]
    if e is None:
        continue

    libs[lib] = dict(path=f"copying/{lib}.txt", home=e["home"])
    copying = e["copying"]

    filtering = identity
    if e.get("html") and html2text is not None:
        filtering = html2text

    if copying.startswith("http://") or copying.startswith("https://"):
        text = fetch_url_text(copying, lib)
        output_lines = filtering(text).split("\n")
    else:
        output_lines = copying.split("\n")

    with open(f"ecmwflibs/copying/{lib}.txt", "w", encoding="utf-8") as f:
        for n in output_lines:
            print(n, file=f)

    with open("ecmwflibs/copying/list.json", "w", encoding="utf-8") as f:
        print(json.dumps(libs), file=f)


assert len(missing) == 0, json.dumps(missing, indent=4, sort_keys=True)
