#!/usr/bin/env python3
from Magics import macro as magics


def test_magics_plot():

    # Setting of the output file name
    output = magics.output(
        output_formats=["png"],
        output_name_first_page_number="off",
        output_name="magics1",
    )

    # Import the  data
    data = magics.mgrib(
        grib_input_file_name="data.grib",
    )

    # proj = magics.mmap(subpage_map_projection="mollweide")
    # proj = magics.mmap(subpage_map_projection="cylindrical")
    proj = magics.mmap(subpage_map_projection="robinson")

    # Apply an automatic styling
    contour = magics.mcont(
        contour_automatic_setting="ecmwf",
    )
    coast = magics.mcoast()
    magics.plot(output, proj, data, contour, coast)
