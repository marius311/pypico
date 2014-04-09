# Manually make sure our C types and Fortran types are the same size
# See corresponding line in fpico_interface.f90
from libc.stdint cimport uint32_t, uint64_t
ctypedef public uint64_t fpint
ctypedef public double   fpreal
ctypedef public uint32_t fpnchar
from numpy import float64 as np_fpreal


# This is needed so that Ctrl+C kills the program even if inside Python code
import signal
signal.signal(signal.SIGINT, signal.SIG_DFL)


import traceback, sys, os, pypico
from pypico import CantUsePICO
from libc.stdlib cimport malloc
from libc.string cimport memcpy
from numpy cimport PyArray_DATA
from numpy import array
from cpython.ref cimport PyObject, Py_XDECREF
cdef extern from "Python.h":
    void Py_Initialize()
cdef extern void initpico()





cdef public void pico_init(bint _kill_on_error):
    """
    This must be called before calling any other PICO interface functions.

    Parameters:
    -----------
    _kill_on_error : bool
        Set to True to kill the program immediately on a Python error and print
        an error message, or set to False to do your own error handling by
        using `Py_checkError`.
    """
    Py_Initialize()
    initpico()
    global kill_on_error
    kill_on_error =  not (_kill_on_error==0)

cdef public void print_last_exception_():
    """Print a stack-trace for the last Python exception"""
    global last_exception
    print_exception(last_exception)

def print_exception(e):
    """Print a Python exception."""
    traceback.print_exception(*e)

cdef void handle_exception(e):
    """Handle exception e given the kill_on_error option."""
    global kill_on_error, last_exception
    last_exception = (type(e), e, sys.exc_info()[2], None, sys.stderr)
    if kill_on_error:
        print_exception(last_exception)
        os._exit(1)
    else:
        raise



#============
# C interface
#============

cdef public pico_load(char *filename):
    """
    Load a PICO data file.

    Parameters:
    -----------
    filename : char*
        The filename

    Returns:
    --------
    pico : PyObject*
        The loaded pico object, which should be passed to other functions.
        If `kill_on_error` is False, call `pico_check_success` on this object
        to ensure loading succeded. 
    """
    try:
        return pypico.load_pico(str(filename))
    except Exception as e:
        handle_exception(e)



cdef public bint pico_check_success(result):
    """
    If `kill_on_error` is False, call pico_check_success on the object
    return from `pico_load` to ensure loading succeded. 
    """
    return result!=None



cdef public pico_compute_result_dict(pico, params, outputs):
    """
    Call PICO to compute a result.

    Parameters:
    -----------
    pico : PyObject*
        The pico object returned from `pico_load`.
    params : PyObject*
        A parameter dictionary containing input parameters and values.
    outputs : PyObject*
        A list containing the requested outputs.

    Returns:
    --------
    result : PyObject*
        The result of the PICO computation, which can be read with `pico_read_output`. 
        It is up to the user to free this memory with `pico_free_result`.
    """
    try:
        verbose = getattr(pico,'_verbose',False)
        if verbose:
            print 'Calling PICO with parameters: %s'%params
            print 'Getting the outputs: %s'%outputs
            try:
                result = pico.get(outputs=outputs,**params)
                if verbose: print 'Succesfully called PICO.'
                return result
            except CantUsePICO as c:
                if verbose: print 'Failed to call PICO: %s'%c
    except Exception as e:
        handle_exception(e)

cdef public pico_compute_result(pico, int nparams, char* names[], double values[]):
    """
    Call PICO to compute a result. (Assumes all outputs are requested.)

    Parameters:
    -----------
    pico : PyObject*
        The pico object returned from `pico_load`.
    names : char*[]
        An array of parameter names. 
    values : double[]
        An array of parameter values.
    nparams : int
        The length of the name/value arrays.

    Returns:
    --------
    result : PyObject*
        The result of the PICO computation, which can be read with `pico_read_output`. 
        It is up to the user to free this memory with `pico_free_result`.
    """
    try:
        return pico_compute_result2(pico,nparams,names,values,0,NULL)
    except Exception as e:
        handle_exception(e)


cdef public pico_compute_result2(pico, int nparams, char* names[], double values[], int noutputs, char *outputs[]):
    """
    Call PICO to compute a result.

    Parameters:
    -----------
    pico : PyObject*
        The pico object returned from `pico_load`.
    names : char*[]
        An array of parameter names. 
    values : double[]
        An array of parameter values.
    nparams : int
        The number of name/value pairs.
    outputs : char*[]
        An array of requested output names.
    noutputs : int
        The length of the outputs array.

    Returns:
    --------
    result : PyObject*
        The result of the PICO computation, which can be read with `pico_read_output`. 
        It is up to the user to free this memory with `pico_free_result`.

    """
    try:
        return pico_compute_result_dict(pico,
                                        {names[i]:values[i] for i in range(nparams)},
                                        [outputs[i] for i in range(noutputs)])
    except Exception as e:
        handle_exception(e)




cdef public void pico_read_output(result, char *name, double **output, int *istart, int *iend):
    """
    Read an output from a computed PICO result.
    
    Parameters:
    -----------
    result : PyObject*
        The `result` object as returned by a `pico_compute_result` variant.
    name : char*
        The name of the desired output.
    result : double**
        A pointer to a double[] which will hold the output array. If the double[] array
        is NULL, it will be allocated and the pointer returned. In either case,
        it is up to the user to free the memory.
    istart, iend : int*
        Start and end indices. Set to -1 to read all values.
        These will be set to the starting and ending indices which were read.
    """
    try:
        arr = result[name]
        if arr.dtype.itemsize != sizeof(double): arr=array(arr,dtype=np_fpreal)
        if (iend[0]<0) or (iend[0]>arr.size): iend[0]=arr.size
        if (istart[0]<0): istart[0]=0
        nresult = iend[0]-istart[0]+1
        if output[0]==NULL: output[0]=<double*>malloc(sizeof(double)*nresult)
        memcpy(output[0],PyArray_DATA(arr[istart[0]:]),sizeof(double)*nresult)
    except Exception as e:
        handle_exception(e)



cdef public void pico_get_output_len(result, char *name, int *nresult):
    """
    Get the maximum length of an output array.

    Parameters:
    -----------
        result : PyObject*
            The result returned from a `pico_compute_result` variant.
        name : char* 
            The name of the output.

    Returns:
    --------
    nresult : int*
        The length of the output array.
    """
    try:    
        nresult[0] = result[name].size
    except Exception as e:
        handle_exception(e)


cdef public void pico_free_result(result):
    """
    Free the memory of a result from a `pico_compute_result` variant.
    """
    try:
        Py_XDECREF(<PyObject*>result)
    except Exception as e:
        handle_exception(e)


cdef public bint pico_has_output(pico, char *name):
    """
    Check whether a PICO result has a given output.

    Parameters:
    -----------
    pico : PyObject*
        The pico object returned from `pico_load`.
    name : char *
        The name to check.

    Returns:
    --------
    result : bool
        Whether the output exists.
    """    
    try:
        return name in pico.outputs
    except Exception as e:
        handle_exception(e)


cdef public void pico_set_verbose(pico, bint verbose):
    """
    Set verbose option.

    Parameters:
    -----------
    pico : PyObject*
        The pico object returned from `pico_load`.
    verbose : bool
        Verbosity.
    """
    try:
        pico._verbose = (verbose==True)
    except Exception as e:
        handle_exception(e)


#==================
# Fortran interface
#==================


gpico = None
gparams = None
goutputs = None
gresult = None
gverbose = False


cdef char* add_null_term(char *str, fpnchar nstr):
    """Convert a Fortran string to a C string by adding a null terminating character"""
    cdef char *_str = <char*>malloc(sizeof(char)*(nstr+1))
    memcpy(_str,str,nstr)
    _str[nstr]=0
    return _str


cdef public void fpico_init_(fpint *_kill_on_error):
    pico_init(_kill_on_error[0])


cdef public void fpico_load_(char *filename, fpnchar nfilename):
    try:
        global gpico
        gpico = pico_load(add_null_term(filename,nfilename))
        gparams = dict()
    except Exception as e:
        handle_exception(e)


cdef public void fpico_reset_params_():
    try:
        global gparams
        gparams = dict()
    except Exception as e:
        handle_exception(e)


cdef public void fpico_set_param_(char *name, double *value, fpnchar nname):
    try:
        global gparams
        gparams[str(add_null_term(name,nname))]=value[0]
    except Exception as e:
        handle_exception(e)


cdef public void fpico_set_param_eval_(char *name, char *value, fpnchar nname, fpnchar nvalue):
    try:
        global gparams
        gparams[str(add_null_term(name,nname))]=eval(str(add_null_term(value,nvalue)))
    except Exception as e:
        handle_exception(e)


cdef public void fpico_reset_requested_outputs_():
    try:
        global goutputs
        goutputs = []
    except Exception as e:
        handle_exception(e)


cdef public void fpico_request_output_(char *name, fpnchar nname):
    try:
        global goutputs
        goutputs.append(str(add_null_term(name,nname)))
    except Exception as e:
        handle_exception(e)


cdef public void fpico_compute_result_(int *success):
    try:
        global gpico, gparams, goutputs, gresult, gverbose
        gresult = pico_compute_result_dict(gpico,gparams,goutputs)
        success[0] = (gresult!=None)
    except Exception as e:
        handle_exception(e)

cdef public void fpico_read_output_(char *name, fpreal *output, fpint *istart, fpint *iend, fpnchar nname):
    try:
        res = gresult[str(add_null_term(name,nname))]
        if res.dtype.itemsize != sizeof(fpreal): res=array(res,dtype=np_fpreal)
        memcpy(output,PyArray_DATA(res[istart[0]:]),sizeof(fpreal)*(iend[0] - istart[0] + 1))
    except Exception as e:
        handle_exception(e)

cdef public void fpico_get_output_len_(char *name, fpint *len, fpnchar nname):
    try:
        global gresult
        len[0] = gresult[str(add_null_term(name,nname))].size
    except Exception as e:
        handle_exception(e)


cdef public void fpico_set_verbose_(fpint *verbose):
    try:
        global gpico
        gpico._verbose = (verbose[0]!=0)
    except Exception as e:
        handle_exception(e)


