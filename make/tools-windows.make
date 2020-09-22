tools.mingw64_nt:
	vcpkg install netcdf-c:$(WINARCH)-windows
	vcpkg install pango:$(WINARCH)-windows
	vcpkg install proj:$(WINARCH)-windows
	vcpkg install pthread:$(WINARCH)-windows
	vcpkg install pthread:x86-windows
	pip install ninja wheel dll-diagnostics
