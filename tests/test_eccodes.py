import ecmwflibs


def test_versions():

    versions = ecmwflibs.versions()
    assert "eccodes" in versions, versions
    assert "MagPlus" in versions, versions
    assert "ecmwflibs" in versions, versions

    assert ecmwflibs.find("eccodes") is not None
    assert ecmwflibs.find("MagPlus") is not None
