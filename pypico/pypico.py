"""
Parameters for the Impatient Cosmologist
Author: Marius Millea
"""

_version = '3.1.0'

import cPickle, imp, os, sys, numpy, subprocess, hashlib, time


""" Loaded datafiles will residue in this empty module. """
sys.modules['pypico.datafiles']=imp.new_module('pypico.datafiles')

def get_folder():
    """Get the folder where PICO was installed"""
    return os.path.dirname(os.path.abspath(__file__))

def get_include():
    """Get include flags needed for compiling C/Fortran code with the PICO library."""
    return subprocess.check_output(['python-config','--includes']).strip() + \
            ' -I%s'%numpy.get_include() + \
            ' -I%s'%os.path.dirname(os.path.abspath(__file__))


def get_link():
    """Get link flags needed for linking C/Fortran code with the PICO library."""
    return '-L%s -lpico '%os.path.dirname(os.path.abspath(__file__)) + \
            '-L%s/lib '%subprocess.check_output(['python-config','--prefix']).strip() + \
            subprocess.check_output(['python-config','--libs']).strip()


class PICO():
    """ 
    This is the base class for anyone creating a custom PICO datafile. 
    It represents a mapping from input values to output values.
    
    Note that if the input values are scalars and the output values 
    are vectors, then the code in this library can be used to call the 
    PICO object from C/Fortran.
    
    The fundamental methods are inputs() and outputs() which list possible
    inputs and returned outputs, and get(**inputs) which gets the outputs
    given some inputs.
    """
    
    def inputs(self):
        """
        Returns a list of strings corresponding to names of valid inputs.
        The get() method accepts keyword arguments corresponding to these inputs.
        """
        raise NotImplementedError
    
    
    def outputs(self):
        """
        Returns a list of strings corresponding to names of possible outputs.
        The get() method returns a dictionary with keys corresponding to these outputs. 
        """
        raise NotImplementedError

    def get(self,outputs=None,**inputs):
        """
        Evaluate this PICO function for the given **inputs.
        The keyword argument 'outputs' can specify a a subset of outputs 
        to actually calculate, or it can be None to calculate all outputs
        returned by PICO.outputs()
        """
        raise NotImplementedError


class CantUsePICO(Exception): 
    """
    This Exception is raised if for any reason 
    (including bad input values, failure load some files, etc...)
    PICO.get() cannot compute the result. 
    """
    pass

    
    
def _version_ok(version):
    """Checks for compatibility of a PICO datafile."""
    global _version
    mine = map(int,_version.split('.'))
    theirs = map(int,version.split('.'))
    return mine[:2]==theirs[:2] and mine[2]>=theirs[2]


def load_pico(datafile, module=None, check_version=True):
    """
    Load a PICO data datafile and return a PICO object.
    
    If module is not None, it can specify a path to a Python file, which will 
    be used instead of the code contained in the datafile. This is generally 
    used for debugging purposes only.
    """
    
    try:
        with open(datafile) as f: data = cPickle.load(f)
    except Exception as e:
        raise Exception("Failed to open PICO datafile '%s'\n%s"%(datafile,e.message))
    
    if module: 
        with open(module) as f: code = f.read()
    else:
        code = data['code']
        
    try:
        mymod = imp.new_module(data['module_name'])
        exec code in mymod.__dict__
    except Exception as e:
        raise Exception("Error executing PICO code for datafile '%s'\n%s"%(datafile,e))

    sys.modules[data['module_name']]=mymod
    
    if check_version:
        if 'version' not in data:
            print "Warning: PICO datafile does not have version. Can't check compatibility."
        elif not _version_ok(data.get('version')):
            raise Exception("You PICO version (%s) and the PICO version used to create the datafile '%s' (%s) are incompatible."%(_version,datafile,data['version']))
    
    pico = cPickle.loads(data['pico'])
    pico._code = data['code']
    return pico

    
def create_pico(codefile,datafile):
    """
    Create a PICO datafile.
    
    A PICO datafile is a Pickle of a dictionary which contains 
    some Python code and an instance of a PICO class.
    
    Arguments:    
        codefile - A path to Python module which contains a get_pico function. The 
                   function should return a PICO object which gets Pickled into the 
                   datafile.
        datafile - Path for the output datafile
    """
    
    print "Creating PICO datafile..."
    with open(codefile) as f: code = f.read()
    name = 'pypico.datafiles.%s'%(hashlib.md5(os.path.abspath(codefile) + time.ctime()).hexdigest())
    mymod = imp.new_module(name)
    exec code in mymod.__dict__
    sys.modules[name]=mymod
    pico = mymod.get_pico()
    print "Saving '%s'..."%(os.path.basename(datafile))
    with open(datafile,'w') as f: cPickle.dump({'code':code,'module_name':name,'pico':cPickle.dumps(pico,protocol=2),'version':_version},f,protocol=2)
    