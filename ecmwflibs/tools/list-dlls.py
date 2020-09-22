#!/usr/bin/env python
import sys
import os

from dlldiag.common import ModuleHeader, WindowsApi

VCPKG = "C:/vcpkg/installed/{}-windows/bin/{}"

def scan_module(module, depth):
    print(" " * depth, "SCANNING", module)
    header = ModuleHeader(module)
    cwd = os.path.dirname(module)
    architecture = header.getArchitecture()
    for dll in header.listAllImports():
        if WindowsApi.loadModule(dll, cwd, architecture) != 0:
            print(" " * depth, "ERROR cannot load", dll)
            continue

        scan_module(VCPKG.format(architecture, dll), depth+3)


scan_module(sys.argv[1], 0)
