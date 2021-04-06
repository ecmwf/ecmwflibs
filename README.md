# ecmwflibs

A Python package that wraps some of ECMWF libraries to be used by Python interfaces to ECMWF software.

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

### Acknowledgement

*ecmwflibs* comes packaged with some third-party open source libraries which are dependencies of *Magics* and *ecCodes*. To display the list of embedded libraries and their copyright notices and/or licenses, please type:

```bash
python3 -m ecmwflibs credits
```
