#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import subprocess
import sys

null = open(os.devnull, "w")


def otool(name):
    try:
        return subprocess.check_output(["otool", "-L", name], stderr=null).decode(
            "utf-8"
        )
    except Exception:
        return ""


def process(name, seen, depth=0):
    if name in seen:
        return
    seen.add(name)
    if name.endswith(".dylib"):
        print(f"{' ' * depth}{name}")
        deps = otool(name)
        for line in deps.split("\n"):
            line = line.strip()
            if line.endswith(":"):
                continue
            bits = line.split()
            if len(bits) < 1:
                continue
            lib = bits[0]
            if lib.startswith("@"):
                continue
            if name == lib:
                continue
            process(lib, seen, depth + 2)


for n in sys.argv[1:]:
    process(n, set())
