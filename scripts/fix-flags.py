#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import sys
import sysconfig

flag = sys.argv[1]
arch = sys.argv[2]

var = sysconfig.get_config_var(flag)

print(var, file=sys.stderr)
var = re.sub(r"-arch \w+", "", var)

var += " -arch " + arch

print(var)
