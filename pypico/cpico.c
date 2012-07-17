#include "cpico.h"

PyObject *pPicoModule;

PyObject* Py_Check(PyObject *result){
	if (result==NULL){
		if (PyErr_Occurred()) PyErr_Print();
		else printf("Unspecified Python error.");
		exit(1);
	}
	else return result;
}

PyObject* get_pico_module(void){
	/**
	 * Returns the pypico module.
	 */
	if (!pPicoModule){
		PyObject *pName;
	    Py_Initialize();
	    Py_Check(pName = PyString_FromString("pypico"));
	    Py_Check(pPicoModule = PyImport_Import(pName));
		Py_DECREF(pName);
	}
	return pPicoModule;
}


PyObject* pico_load(char *file){
	/**
	 * Load a PICO data file.
	 *
	 * Returns an object which can be passed to other PICO functions.
	 *
	 * Paramters:
	 * ----------
	 *
	 * file : *char
	 * 		The filename of the datafile
	 *
	 */
	PyObject *pPico, *pFunc, *pArg;
    Py_Initialize();
    Py_Check(pFunc = PyObject_GetAttrString(get_pico_module(), "load_pico"));
	Py_Check(pArg = Py_BuildValue("(s)",file));
	Py_Check(pPico = PyObject_CallObject(pFunc,pArg));
	Py_DECREF(pArg);
    return pPico;
}

PyObject* pico_compute_result_dict(PyObject *pPico, PyObject *pParams){
	/**
	 * Compute the outputs given some inputs.
	 *
	 * This is equivalent to the Python command `pico.get(**inputs)`
	 *
	 * Specific arrays can can be read from the return object
	 * with pico_read_output.
	 *
	 * Parameters:
	 * -----------
	 *
	 * pPico : *PyObject
	 * 		The PICO object as loaded by `pico_load`
	 * pParams : *PyObject
	 * 		A Python dictionary object contains name-value input pairs.
	 *
	 */

	if (pPico==NULL){
		printf("Tried to call PICO without loading a datafile first.\n");
		exit(1);
	}

    PyObject *pArgs, *pResult, *pGet, *pCant;
    Py_Check(pArgs = PyTuple_New(0));
    Py_Check(pGet = PyObject_GetAttrString(pPico, "get"));
    pResult = PyObject_Call(pGet,pArgs,pParams);
    Py_Check(pCant = PyObject_GetAttrString(get_pico_module(), "CantUsePICO"));
    if (pResult==NULL){
    	if (PyErr_ExceptionMatches(pCant)){
    		if (pico_is_verbose(pPico)) PyErr_Print();
    	}
    	else Py_Check(pResult);
    }
    Py_DECREF(pArgs); Py_DECREF(pCant);
    return pResult;
}

void pico_set_verbose(PyObject *pPico, bool verbose){
	/**
	 * Set whether to print out debug messages for calls
	 * to a given PICO object.
	 */
	PyObject_SetAttrString(pPico, "_verbose",verbose ? Py_True : Py_False);
}

bool pico_is_verbose(PyObject *pPico){
	/**
	 * Check whether a given PICO object has the verbose flag.
	 */
	PyObject *pVerbose;
	bool verbose;
	verbose = false;
	if (PyObject_HasAttrString(pPico,"_verbose")){
		pVerbose = PyObject_GetAttrString(pPico, "_verbose");
		verbose = PyBool_Check(pVerbose) && (pVerbose == Py_True);
		Py_DECREF(pVerbose);
	}
	return verbose;
}

PyObject* pico_compute_result(PyObject *pPico, int ninputs, char *names[], double values[]){
	/**
	 * Compute the outputs given some inputs.
	 *
	 * This is equivalent to the Python command `pico.get(**inputs)`
	 *
	 * Specific arrays can can be read from the return object
	 * by passing it pico_read_output.
	 *
	 * Parameters:
	 * -----------
	 *
	 * pPico : *PyObject
	 * 		The PICO object as loaded by `pico_load`
	 * ninputs : int
	 * 		The number of inputs
	 * names : *char[]
	 * values : double[]
	 * 		Length `ninputs` arrays of name-value pairs.
	 *
	 */
    PyObject *pParams, *pName, *pValue;
    int i;
    Py_Check(pParams = PyDict_New());
    for (i=0; i<ninputs; i++){
		Py_Check(pName = PyString_FromString(names[i]));
		Py_Check(pValue = PyFloat_FromDouble(values[i]));
		PyDict_SetItem(pParams,pName,pValue);
		Py_DECREF(pName); Py_DECREF(pValue);
    }
    return pico_compute_result_dict(pPico,pParams);
}

bool pico_has_output(PyObject *pPico, char* key){
	/**
	 * Return true if the PICO object outputs a given key.
	 *
	 * Equivalent to `key in pico.outputs()`
	 *
	 * If `pico_has_output` returns true, then it is safe to call
	 * `pico_read_output` with the same key.
	 */
	bool has;
    PyObject *pOutputsResult, *pContainsResult, *pOutput ;
    Py_Check(pOutputsResult = PyObject_CallMethod(pPico,"outputs",NULL));
    Py_Check(pOutput = PyString_FromString(key));
    Py_Check(pContainsResult = PyObject_CallMethod(pOutputsResult, "__contains__", "(O)", pOutput));
    has = (pContainsResult == Py_True);
    Py_DECREF(pOutputsResult); Py_DECREF(pContainsResult); Py_DECREF(pOutput);
    return has;
}


void pico_free_result(PyObject *pResult){
	/**
	 * Free the memory used by a given result.
	 */
	Py_XDECREF(pResult);
}

void pico_get_output_len(PyObject *pResult, char *key, int *nresult){
	/**
	 * Gets the maximum length of the array returned by the corresponding
	 * call to `pico_read_output`
	 *
	 * Parameters
	 * ----------
	 * pResult : PyObject*
	 * 		The `pResult` object as returned by `pico_compute_result`
	 * key : char*
	 *      The name of the desired output.
	 * nresult : int*
	 * 		The returned length
	 *
	 */
	if (pResult==NULL){
		printf("Tried to get PICO output without computing result first.");
		exit(1);
	}

	PyArrayObject *pArr;
	pArr = (PyArrayObject*)PyDict_GetItemString(pResult,key);
	if (pArr==NULL){
		if (PyErr_Occurred()) PyErr_Print();
		printf("PICO couldn't compute the output '%s'\n",key);
		exit(1);
	}
	else{
		(*nresult) = PyArray_DIMS(pArr)[0];
	}

}

void pico_read_output(PyObject *pResult, char *key, double** result, int* nresult){
	/**
	 * Read an output from a computed PICO result.
	 *
	 * In Python, a PICO "result" is the return value of `PICO.get()`
	 * which is a dictionary (mapping output names to arrays).
	 *
	 * This C function corresponds to getting values from that dictionary.
	 *
	 * Parameters:
	 * -----------
	 *
	 * pResult : PyObject*
	 * 		The `pResult` object as returned by `pico_compute_result`
	 * key : char*
	 *      The name of the desired output.
	 * result : double**
	 * 		A pointer to a double[] which will hold the result. If the double[] array
	 * 		is NULL, it will be allocated and the pointer returned. In either case,
	 * 		it is up to the user to free the memory.
	 * nresult : int*
	 * 		How many values to write to `result`. Set to -1 to write all values.
	 * 		The return value is how many values were actually written.
	 */

	if (pResult==NULL){
		printf("Tried to get PICO output without computing result first.");
		exit(1);
	}

	PyArrayObject *pArr;
	pArr = (PyArrayObject*)PyDict_GetItemString(pResult,key);
	if (pArr==NULL){
		if (PyErr_Occurred()) PyErr_Print();
		printf("PICO couldn't compute the output '%s'\n",key);
		exit(1);
	}
	else{
		if ((*nresult)<0 || (*nresult)>PyArray_DIMS(pArr)[0]) (*nresult) = PyArray_DIMS(pArr)[0];
		if ((*result)==NULL) (*result) = malloc(sizeof(double)*(*nresult));
		memcpy(*result, (double*) PyArray_GETPTR1(pArr,0),sizeof(double)*(*nresult));
	}

}



