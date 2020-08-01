# ecmwflibs

A Python package that wraps some of ECMWF libraries.

The snippet of code below should return the path to the *ecCodes* shared library.

```python
import ecmwflibs
lib = ecmwflibs.find("eccodes")
```

You can  get the versions of libraries:

```python
import ecmwflibs
print(ecmwflibs.versions())
{'eccodes': '2.19.0', 'magics': '4.4.3', 'ecmwflibs': '0.0.12'}
```
