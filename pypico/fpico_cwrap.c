#include <Python.h>
#include "cpico.h"
#include <stdbool.h>

PyObject *pPico, *pResult, *pParams, *pCantUsePICO;

void fpico_load__(char *file, int *len){
	Py_XDECREF(pPico); Py_XDECREF(pParams);
	char _file[*len+1]; memcpy(&_file,file,*len); _file[*len]=0;
	Py_Check(pPico = pico_load(_file));
    Py_Check(pParams = PyDict_New());
}

void fpico_set_param__(char *name, int *len, double *value){
    PyObject *pName, *pValue;
	char _name[*len+1]; memcpy(&_name,name,*len); _name[*len]=0;
	Py_Check(pName = PyString_FromString(_name));
	Py_Check(pValue = PyFloat_FromDouble(*value));
	PyDict_SetItem(pParams,pName,pValue);
	Py_DECREF(pName); Py_DECREF(pValue);
}

bool fpico_compute_result__(){
	Py_XDECREF(pResult);
	pResult = pico_compute_result_dict(pPico, pParams);
	return pResult!=NULL;
}

int fpico_has_output__(char *output, int *len){
	char _output[*len+1]; memcpy(&_output,output,*len); _output[*len]=0;
	return pico_has_output(pPico,_output) ? 1 : 0;
}

void fpico_read_result__(char *output, int *len, double res[], int *istart, int *iend){
	char _output[*len+1]; memcpy(&_output,output,*len); _output[*len]=0;
	if (pico_has_output(pPico,_output)){
		memcpy(res,&pico_read_result(pResult,_output,*iend)[*istart],sizeof(double)*(*iend - *istart + 1));
	}
}
