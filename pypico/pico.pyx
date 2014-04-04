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


cdef extern from "Python.h":
    void Py_Initialize()

cdef extern void initpico()

cdef public void pico_init(fpint _kill_on_error):
    Py_Initialize()
    initpico()
    global kill_on_error
    kill_on_error =  not (_kill_on_error==0)


cdef public void fpico_init_(fpint *_kill_on_error):
    pico_init(_kill_on_error[0])


cdef char* add_null_term(char *str, fpnchar nstr):
    """Convert a Fortran string to a C string by adding a null terminating character"""
    cdef char *_str = <char*>malloc(sizeof(char)*(nstr+1))
    memcpy(_str,str,nstr)
    _str[nstr]=0
    return _str


cdef public print_last_exception_():
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



gpico = None
gparams = None
goutputs = None
gresult = None
gverbose = False


cdef public pico_load(char *file):
    try:
        return pypico.load_pico(str(file))
    except Exception as e:
        handle_exception(e)


cdef public void fpico_load_(char *file, fpnchar nfile):
    try:
        global gpico
        gpico = pico_load(add_null_term(file,nfile))
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
        if gverbose:
            print 'Calling PICO with parameters: %s'%gparams
            print 'Getting the outputs: %s'%goutputs
        try:
            gresult = gpico.get(outputs=goutputs,**gparams)
            success[0] = 1
            if gverbose: print 'Succesfully called PICO.'
        except CantUsePICO as c:
            success[0] = 0
            if gverbose: print 'Failed to call PICO: %s'%c

    except Exception as e:
        handle_exception(e)

cdef public void fpico_read_output_(char *key, fpreal *output, fpint *istart, fpint *iend, fpnchar nkey):
    try:
        res = gresult[str(add_null_term(key,nkey))]
        if res.dtype.itemsize != sizeof(fpreal): res=array(res,dtype=np_fpreal)
        memcpy(output,PyArray_DATA(res[istart[0]:]),sizeof(fpreal)*(iend[0] - istart[0] + 1))
    except Exception as e:
        handle_exception(e)

cdef public void fpico_get_output_len_(char *key, fpint *len, fpnchar nkey):
    try:
        global gresult
        len[0] = gresult[str(add_null_term(key,nkey))].size
    except Exception as e:
        handle_exception(e)


cdef public void fpico_set_verbose_(fpint *verbose):
    try:
        global gverbose
        gverbose = (verbose[0]!=0)
    except Exception as e:
        handle_exception(e)


