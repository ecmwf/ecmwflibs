#!/usr/bin/env python3

import os

from Magics import macro as magics


def test_magics():
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

    proj = magics.mmap(subpage_map_projection="mollweide")

    # Apply an automatic styling
    contour = magics.mcont(
        contour_automatic_setting="ecmwf",
    )
    coast = magics.mcoast()
    magics.plot(output, proj, data, contour, coast)
