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

void check_loaded(void){
	if (pPico==NULL){
		printf("Tried to call PICO without loading a datafile first.\n");
		exit(1);
	}
}

void check_computed(void){
	check_loaded();
	if (pResult==NULL){
		printf("Tried to get PICO output without computing result first.\n");
		exit(1);
	}
}

void fpico_set_param__(char *name, int *len, double *value){
	check_loaded();
    PyObject *pName, *pValue;
	char _name[*len+1]; memcpy(&_name,name,*len); _name[*len]=0;
	Py_Check(pName = PyString_FromString(_name));
	Py_Check(pValue = PyFloat_FromDouble(*value));
	PyDict_SetItem(pParams,pName,pValue);
	Py_DECREF(pName); Py_DECREF(pValue);
}

bool fpico_compute_result__(void){
	check_loaded();
	Py_XDECREF(pResult);
	pResult = pico_compute_result_dict(pPico, pParams);
	return pResult!=NULL;
}

int fpico_has_output__(char *output, int *len){
	check_loaded();
	char _output[*len+1]; memcpy(&_output,output,*len); _output[*len]=0;
	return pico_has_output(pPico,_output) ? 1 : 0;
}

void fpico_get_output_len__(char *key, int *len, int *nresult){
	check_computed();
	char _key[*len+1]; memcpy(&_key,key,*len); _key[*len]=0;
	pico_get_output_len(pResult,_key,nresult);
}


void fpico_read_output__(char *key, int *len, double result[], int *istart, int *iend){
	check_computed();
	char _key[*len+1]; memcpy(&_key,key,*len); _key[*len]=0;
	double *_result=NULL; int nresult=-1;

	pico_read_output(pResult,_key,&_result,&nresult);
	memcpy(result,&_result[*istart],sizeof(double)*(*iend - *istart + 1));
}
