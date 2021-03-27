import sys

from ecmwflibs import credits

if sys.argv[-1] != "credits":
    print("Type 'python -m ecmwflibs credits' to see the")
    print("Open Source software installed with ecmwflibs.")
    exit(0)

credits()
