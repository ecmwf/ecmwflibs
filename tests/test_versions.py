import ecmwflibs


def test_versions():

    versions = ecmwflibs.versions()
    assert "eccodes" in versions, versions
    assert "magics" in versions, versions
    assert "ecmwflibs" in versions, versions

    assert ecmwflibs.find("eccodes") is not None
    assert ecmwflibs.find("magics") is not None
