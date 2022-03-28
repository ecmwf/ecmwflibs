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
{'eccodes': '2.19.0', 'magics': '4.4.3', 'ecmwflibs': '0.4.5'}
```

## Possible issues

If you get this message on Windows:

`DLL load failed while importing _ecmwflibs: The specified module could not be found.`

this means that the C++ runtime library is not installed. Please download and install `vc_redist.x86.exe` or `vc_redist.x64.exe`
from https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads.

## Acknowledgements

*ecmwflibs* comes packaged with some third-party open source libraries which are dependencies of *Magics* and *ecCodes*. To display the list of embedded libraries and their copyright notices and/or licenses, please type:

```bash
python3 -m ecmwflibs credits
```
