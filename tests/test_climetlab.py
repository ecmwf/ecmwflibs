#!/usr/bin/env python3
import pytest
from Magics import macro


def test_climetlab_grib():
    actions = [
        macro.output(
            output_formats=["png"],
            output_name="climetlab_grib_1",
            output_name_first_page_number=False,
            output_width=680,
            page_frame=False,
            page_id_line=False,
            page_x_length=10.0,
            page_y_length=5.555555555555555,
            subpage_x_length=10.0,
            subpage_x_position=0.0,
            subpage_y_length=5.555555555555555,
            subpage_y_position=0.0,
            super_page_x_length=10.0,
            super_page_y_length=5.555555555555555,
        ),
        macro.mmap(
            subpage_lower_left_latitude=33.0,
            subpage_lower_left_longitude=-27.0,
            subpage_map_projection="cylindrical",
            subpage_upper_right_latitude=73.0,
            subpage_upper_right_longitude=45.0,
        ),
        macro.mcoast(
            map_boundaries=True,
            map_coastline_colour="tan",
            map_coastline_land_shade=True,
            map_coastline_land_shade_colour="cream",
            map_grid=False,
            map_grid_colour="tan",
            map_grid_frame=True,
            map_grid_frame_thickness=5,
            map_label=False,
        ),
        macro.mgrib(
            grib_field_position=0,
            grib_file_address_mode="byte_offset",
            grib_input_file_name="climetlab.grib",
        ),
        macro.mcont(
            contour_automatic_setting="climetlab",
            legend=False,
        ),
        macro.mcoast(
            map_grid=False,
            map_grid_frame=True,
            map_grid_frame_thickness=5,
            map_label=False,
        ),
    ]

    print(actions)

    macro.plot(*actions)

    actions = [
        macro.output(
            output_formats=["png"],
            output_name="climetlab_grib_2",
            output_name_first_page_number=False,
            output_width=680,
            page_frame=False,
            page_id_line=False,
            page_x_length=10.0,
            page_y_length=5.555555555555555,
            subpage_x_length=10.0,
            subpage_x_position=0.0,
            subpage_y_length=5.555555555555555,
            subpage_y_position=0.0,
            super_page_x_length=10.0,
            super_page_y_length=5.555555555555555,
        ),
        macro.mmap(
            subpage_lower_left_latitude=33.0,
            subpage_lower_left_longitude=-27.0,
            subpage_map_projection="cylindrical",
            subpage_upper_right_latitude=73.0,
            subpage_upper_right_longitude=45.0,
        ),
        macro.mcoast(
            map_boundaries=True,
            map_coastline_colour="tan",
            map_coastline_land_shade=True,
            map_coastline_land_shade_colour="cream",
            map_grid=False,
            map_grid_colour="tan",
            map_grid_frame=True,
            map_grid_frame_thickness=5,
            map_label=False,
        ),
        macro.mgrib(
            grib_field_position=526,
            grib_file_address_mode="byte_offset",
            grib_input_file_name="climetlab.grib",
        ),
        macro.mcont(
            contour_automatic_setting="climetlab",
            legend=False,
        ),
        macro.mcoast(
            map_grid=False,
            map_grid_frame=True,
            map_grid_frame_thickness=5,
            map_label=False,
        ),
    ]

    print(actions)
    macro.plot(*actions)


@pytest.mark.parametrize("filename", ["climetlab.nc", "test.nc4"])
def test_climetlab_netcdf(filename):
    from Magics import macro

    output = filename.replace(".", "-") + ".png"

    actions = [
        macro.output(
            output_file=output,
            output_width=680,
            page_frame=False,
            page_id_line=False,
            page_x_length=10,
            page_y_length=5.555555555555555,
            subpage_frame=False,
            subpage_x_length=10,
            subpage_x_position=0.0,
            subpage_y_length=5.555555555555555,
            subpage_y_position=0.0,
            super_page_frame=False,
            super_page_x_length=10,
            super_page_y_length=5.555555555555555,
        ),
        macro.mmap(
            subpage_lower_left_latitude=33.0,
            subpage_lower_left_longitude=-27.0,
            subpage_map_projection="cylindrical",
            subpage_upper_right_latitude=73.0,
            subpage_upper_right_longitude=45.0,
        ),
        macro.mcoast(
            map_boundaries=True,
            map_coastline_colour="tan",
            map_coastline_land_shade=True,
            map_coastline_land_shade_colour="cream",
            map_grid=False,
            map_grid_colour="tan",
            map_grid_frame=True,
            map_grid_frame_thickness=5,
            map_label=False,
        ),
        macro.mnetcdf(
            netcdf_filename=filename,
            netcdf_value_variable="t2m",
        ),
        macro.mcont(
            contour_automatic_setting="climetlab",
            legend=False,
        ),
        macro.mcoast(
            map_grid=False,
            map_grid_frame=True,
            map_grid_frame_thickness=5,
            map_label=False,
        ),
    ]

    print(actions)

    macro.plot(*actions)


if __name__ == "__main__":
    test_climetlab_netcdf()
    # test_climetlab_grib()
