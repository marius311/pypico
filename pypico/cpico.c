#include "cpico.h"

PyObject *pPicoModule;

PyObject* get_pico_module(){
	if (!pPicoModule){
		PyObject *pName;
	    Py_Initialize();
	    Py_Check(pName = PyString_FromString("pypico"));
	    Py_Check(pPicoModule = PyImport_Import(pName));
		Py_DECREF(pName);
	}
	return pPicoModule;
}

PyObject* Py_Check(PyObject *result){
	if (result==NULL){
		if (PyErr_Occurred()) PyErr_Print();
		else printf("Unspecified Python error.");
		exit(1);
	}
	else return result;
}

PyObject* pico_load(char *file){
	PyObject *pPico, *pFunc, *pArg;
    Py_Initialize();
    Py_Check(pFunc = PyObject_GetAttrString(get_pico_module(), "load_pico"));
	Py_Check(pArg = Py_BuildValue("(s)",file));
	Py_Check(pPico = PyObject_CallObject(pFunc,pArg));
	Py_DECREF(pArg);
    return pPico;
}

PyObject* pico_compute_result_dict(PyObject *pPico, PyObject *pParams){
    PyObject *pArgs, *pResult, *pGet, *pCant;
    Py_Check(pArgs = PyTuple_New(0));
    Py_Check(pGet = PyObject_GetAttrString(pPico, "get"));
    pResult = PyObject_Call(pGet,pArgs,pParams);
    Py_Check(pCant = PyObject_GetAttrString(get_pico_module(), "CantUsePICO"));
    if (pResult==NULL){
    	if (PyErr_ExceptionMatches(pCant)) PyErr_Print();
    	else Py_Check(pResult);
    }
    Py_DECREF(pArgs); Py_DECREF(pCant);
    return pResult;
}

PyObject* pico_compute_result(PyObject *pPico, int nparams, char *names[], double values[]){
    PyObject *pParams, *pName, *pValue;
    int i;
    Py_Check(pParams = PyDict_New());
    for (i=0; i<nparams; i++){
		Py_Check(pName = PyString_FromString(names[i]));
		Py_Check(pValue = PyFloat_FromDouble(values[i]));
		PyDict_SetItem(pParams,pName,pValue);
		Py_DECREF(pName); Py_DECREF(pValue);
    }
    return pico_compute_result_dict(pPico,pParams);
}

bool pico_has_output(PyObject *pPico, char* output){
	bool has;
    PyObject *pOutputsResult, *pContainsResult, *pOutput ;
    Py_Check(pOutputsResult = PyObject_CallMethod(pPico,"outputs",NULL));
    Py_Check(pOutput = PyString_FromString(output));
    Py_Check(pContainsResult = PyObject_CallMethod(pOutputsResult, "__contains__", "(O)", pOutput));
    has = (pContainsResult == Py_True);
    Py_DECREF(pOutputsResult); Py_DECREF(pContainsResult); Py_DECREF(pOutput);
    return has;
}


double* pico_read_result(PyObject *pResult, char *which, int len){
	PyArrayObject *pArr;
	double* res;
	pArr = (PyArrayObject*)PyDict_GetItemString(pResult,which);
	if (pArr==NULL){
		if (PyErr_Occurred()) PyErr_Print();
		printf("PICO not trained on %s",which);
		return NULL;
	}
	else{
		if (len > PyArray_DIMS(pArr)[0]){
			printf("Asking for higher length (e.g. lmax, kmax) than PICO has calculated.\n");
			exit(1);
		}
		else{
			res = (double*) PyArray_GETPTR1(pArr,0);
			return res;
		}
	}

}



