#!/usr/bin/env python
import os
import sys
import json
import shutil

from dlldiag.common import ModuleHeader, WindowsApi

VCPKG = "C:/vcpkg/installed/{}-windows/bin/{}"


def scan_module(module, depth, seen):

    name = os.path.basename(module)

    if name in seen:
        return

    if not os.path.exists(module):
        return

    print(" " * depth, module)
    seen[name] = module

    header = ModuleHeader(module)
    cwd = os.path.dirname(module)
    architecture = header.getArchitecture()
    for dll in header.listAllImports():
        # if WindowsApi.loadModule(dll, cwd, architecture) != 0:
        #     print(" " * depth, "ERROR cannot load", dll)
        #     continue

        scan_module((cwd + "/" + dll), depth + 3, seen)
        scan_module(VCPKG.format(architecture, dll), depth + 3, seen)


seen = {}
scan_module(sys.argv[1], 0, seen)

for k, v in seen.items():
    target = sys.argv[2] + "/" + k
    print("Copy", v, "to", target)
    shutil.copyfile(v, target)
