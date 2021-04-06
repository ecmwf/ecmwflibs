#!/usr/bin/env python
import os
import shutil
import sys

from dlldiag.common import ModuleHeader

VCPKG1 = "C:/vcpkg/installed/{}-windows/bin/{}"
VCPKG2 = "C:/vcpkg/installed/{}-windows/debug/bin/{}"


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
        # print("DEBUG", dll)
        scan_module((cwd + "/" + dll), depth + 3, seen)
        scan_module(VCPKG1.format(architecture, dll), depth + 3, seen)
        scan_module(VCPKG2.format(architecture, dll), depth + 3, seen)


seen = {}
scan_module(sys.argv[1], 0, seen)

for k, v in seen.items():
    target = sys.argv[2] + "/" + k
    print("Copy", v, "to", target)
    shutil.copyfile(v, target)
