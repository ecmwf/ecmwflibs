tools.mingw64_nt:
	vcpkg install netcdf-c:x64-windows
	vcpkg install netcdf-c:x86-windows
	vcpkg install pango:x64-windows
	vcpkg install pango:x86-windows
	vcpkg install proj:x64-windows
	vcpkg install proj:x86-windows
	vcpkg install pthread:x64-windows
	vcpkg install pthread:x86-windows
	pip install ninja
	pip install jinja2 wheel
