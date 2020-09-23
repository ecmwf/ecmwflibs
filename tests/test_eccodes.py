from eccodes import *


def test_versions():

    with open("data.grib") as f:
        grib = codes_grib_new_from_file(f)
        print(codes_get(grib, "date"))
        print(codes_get(grib, "shortName"))
        codes_release(grib)
