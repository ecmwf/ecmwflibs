
#include <stdio.h>
#include <stdlib.h>
#include <netcdf.h>

int main(int argc, const char* argv[]) {
    int ncid, e;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s file.nc\n", argv[0]);
        exit(1);
    }

    if ((e = nc_open(argv[1], NC_NOWRITE, &ncid))) {
        fprintf(stderr,"%s: %s\n", argv[1], nc_strerror(e));
        exit(1);
    }

    printf("%s: file opened successfully\n", argv[1]);

    exit(0);
}
