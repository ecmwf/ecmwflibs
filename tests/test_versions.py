import json

import ecmwflibs


def test_versions():

    versions = ecmwflibs.versions()
    print(json.dumps(versions, sort_keys=True, indent=4))

    assert "eccodes" in versions, versions
    assert "magics" in versions, versions
    assert "ecmwflibs" in versions, versions

    for lib in ("eccodes", "magics"):
        print(lib, ecmwflibs.find(lib))

        assert ecmwflibs.find(lib) is not None


# def test_files():
#     for f in ecmwflibs.files():
#         print(f)
