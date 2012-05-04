#include <Python.h>
#include <numpy/arrayobject.h>
#include <stdbool.h>


PyObject* Py_Check(PyObject *result);

PyObject* pico_load(char *file);

PyObject* pico_compute_result(PyObject *pPico, int nparams, char *names[], double values[]);

PyObject* pico_compute_result_dict(PyObject *pPico, PyObject *pParams);

double* pico_read_result(PyObject *pResult, char *which, int len);

bool pico_has_output(PyObject *pPico, char* output);

