# Tools for Windows

tools.mingw64_nt:
	vcpkg install netcdf-c:$(WINARCH)-windows
	vcpkg install pango:$(WINARCH)-windows
	vcpkg install proj:$(WINARCH)-windows
	vcpkg install expat:$(WINARCH)-windows
	pip install ninja wheel dll-diagnostics
