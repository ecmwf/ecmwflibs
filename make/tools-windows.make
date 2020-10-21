# Tools for Windows

tools.mingw64_nt:
	vcpkg install expat:$(WINARCH)-windows
	vcpkg install netcdf-c:$(WINARCH)-windows
	vcpkg install pango:$(WINARCH)-windows
	vcpkg install sqlite3[core,tool]:$(WINARCH)-windows
	pip install ninja wheel dll-diagnostics
