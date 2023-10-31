from eccodes import codes_get, codes_grib_new_from_file, codes_release


def test_versions():
    with open("data.grib", "rb") as f:
        grib = codes_grib_new_from_file(f)

        date = codes_get(grib, "date")
        assert date == 20130325, date
        print(date)

        print(codes_get(grib, "shortName"))

        codes_release(grib)
