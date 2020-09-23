#!/usr/bin/env python3

from Magics import macro as magics
from Magics.Magics import MagicsError


def test_magics_plot():
    return

    name = "magics"
    # Setting of the output file name
    output = magics.output(
        output_formats=["png"],
        output_name_first_page_number="off",
        output_name="magics",
    )

    # Import the  data
    data = magics.mgrib(
        grib_input_file_name="data.grib",
    )

    # proj = magics.mmap(subpage_map_projection="mollweide")
    proj = magics.mmap(subpage_map_projection="cylindrical")

    # Apply an automatic styling
    contour = magics.mcont(
        contour_automatic_setting="ecmwf",
    )
    coast = magics.mcoast()
    magics.plot(output, proj, data, contour, coast)


def test_magics_exception():

    with pytest.raises(MagicsError):


        name = "magics"
        # Setting of the output file name
        output = magics.output(
            output_formats=["png"],
            output_name_first_page_number="off",
            output_name="magics",
        )

        # Import the  data
        data = magics.mgrib(
            grib_input_file_name="data.grib",
        )

        proj = magics.mmap(
            subpage_lower_left_longitude=0.0,
            subpage_upper_right_longitude=360.0,
            subpage_upper_right_latitude=90.0,
            subpage_map_projection="polar_stereographic",
            subpage_lower_left_latitude=-90.0,
        )

        # Apply an automatic styling
        contour = magics.mcont(
            contour_automatic_setting="ecmwf",
        )
        coast = magics.mcoast()

        magics.plot(output, proj, data, contour, coast)
