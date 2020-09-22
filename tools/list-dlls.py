#!/usr/bin/env python
import os
import sys

from dlldiag.common import ModuleHeader, WindowsApi

VCPKG = "C:/vcpkg/installed/{}-windows/bin/{}"


def scan_module(module, depth, seen):

    if module in seen:
        return

    seen.add(module)

    if not os.path.exists(module):
        return

    print(" " * depth, module)

    header = ModuleHeader(module)
    cwd = os.path.dirname(module)
    architecture = header.getArchitecture()
    for dll in header.listAllImports():
        if WindowsApi.loadModule(dll, cwd, architecture) != 0:
            print(" " * depth, "ERROR cannot load", dll)
            continue

        scan_module((cwd + "/" + dll), depth + 3, seen)
        scan_module(VCPKG.format(architecture, dll), depth + 3, seen)


scan_module(sys.argv[1], 0, set())
