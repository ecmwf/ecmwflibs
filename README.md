# ecmwflibs

A Python package that wraps some of ECMWF libraries.

The snippet of code below should return the path to the *ecCodes* shared library.

```python
import ecmwflibs
lib = ecmwflibs.find("eccodes")
```

