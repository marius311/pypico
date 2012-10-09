#include <Python.h>
#include "cpico.h"

PyObject *pPico, *pResult, *pParams, *pOutputs, *pCantUsePICO;

char* add_null_term(char *str, int nstr){
    char *_str;
    _str = malloc(nstr+1);
    memcpy(_str,str,nstr); 
    _str[nstr]=0;
    return _str;
}

void fpico_reset_params_(void){
    Py_XDECREF(pParams);
    Py_Check(pParams = PyDict_New());
}

void fpico_reset_requested_outputs_(void){
    Py_XDECREF(pOutputs);
    pOutputs = Py_None;
}


void fpico_load_(char *file, int _nfile){
    Py_XDECREF(pPico); Py_XDECREF(pParams);
    char *_file = add_null_term(file,_nfile);
    Py_Check(pPico = pico_load(_file));
    fpico_reset_params_();
    fpico_reset_requested_outputs_();
    free(_file);
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


void fpico_request_output_(char *name, int nname){
    check_loaded();
    PyObject *pName;
    char *_name = add_null_term(name,nname);
    Py_Check(pName = PyString_FromString(_name));
    if (pOutputs == Py_None) Py_Check(pOutputs = PySet_New(NULL));
    PySet_Add(pOutputs,pName);
    Py_DECREF(pName);
    free(_name);
}

void fpico_set_param_(char *name, double *value, int nname){
    check_loaded();
    PyObject *pName, *pValue;
    char *_name = add_null_term(name,nname);
    Py_Check(pName = PyString_FromString(_name));
    Py_Check(pValue = PyFloat_FromDouble(*value));
    PyDict_SetItem(pParams,pName,pValue);
    Py_DECREF(pName); Py_DECREF(pValue);
    free(_name);
}

void fpico_compute_result_(int *success){
    check_loaded();
    Py_XDECREF(pResult);
    pResult = pico_compute_result_dict(pPico, pParams,pOutputs);
    (*success) = pResult==NULL ? (int)0 : (int)1;
    if (pResult!=NULL && pico_is_verbose(pPico)){
        printf("Result: ");
        PyObject_Print(pResult,stdout,0);
        printf("\n");
    }
}

void fpico_has_output_(char *output, int *has, int noutput){
    check_loaded();
    char *_output = add_null_term(output,noutput);
    (*has) = pico_has_output(pPico,_output) ? 1 : 0;
    free(_output);
}

void fpico_get_output_len_(char *key, int *nresult, int nkey){
    check_computed();
    char *_key = add_null_term(key,nkey);
    pico_get_output_len(pResult,_key,nresult);
    free(_key);
}

void fpico_set_verbose_(int *verbose){
    check_loaded();
    pico_set_verbose(pPico,*verbose);
}

void fpico_read_output_(char *key, double *result, int *istart, int *iend, int nkey){
    check_computed();
    char *_key = add_null_term(key,nkey);
    pico_read_output(pResult,_key,&result,istart,iend);
    free(_key);
}
