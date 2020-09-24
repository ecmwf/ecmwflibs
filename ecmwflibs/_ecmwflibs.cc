#include <stdio.h>
#include <Python.h>

#include <eccodes.h>
#include <magics_config.h>

extern "C" const char* magics_install_path(const char* path);

static PyObject* set_magics_install_path(PyObject *self, PyObject *args) {
    char *path;
    if (!PyArg_ParseTuple(args, "s", &path)) {
        return NULL;
    }

    return Py_BuildValue("s", magics_install_path(path));
}


static PyObject* versions(PyObject *self, PyObject *args) {
    long s = grib_get_api_version(); // Force linking

    return Py_BuildValue("{s:s,s:s}",
        "eccodes", ECCODES_VERSION_STR,
        "magics", MAGICS_VERSION_STR);
}

static PyMethodDef ecmwflibs_methods[] = {
    {
        "versions", versions, METH_NOARGS,
        "magics_install_path", set_magics_install_path, METH_VARARGS,
        "Versions",
    },
    {0,}
};

static struct PyModuleDef ecmwflibs_definition = {
    PyModuleDef_HEAD_INIT,
    "ecmwflibs",
    "Load ECMWF libraries.",
    -1,
    ecmwflibs_methods
};

PyMODINIT_FUNC PyInit__ecmwflibs(void) {
    Py_Initialize();
    return PyModule_Create(&ecmwflibs_definition);
}
