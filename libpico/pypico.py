"""
The current PICO version, specified as 'release.major.minor'
Minor version are backwards compatible, whereas major version are not.
"""
_version = '3.0.0'

import re, cPickle, imp, os, sys, numpy, subprocess



def get_include():
    """Get include flags needed for compiling C/Fortran code with the PICO library."""
    return subprocess.check_output(['python-config','--includes']).strip() + \
            ' -I%s'%numpy.get_include() + \
            ' -I%s'%os.path.dirname(os.path.abspath(__file__))


def get_link():
    """Get link flags needed for compiling C/Fortran code with the PICO library."""
    return '-L%s -lpico3 '%os.path.dirname(os.path.abspath(__file__)) + \
            subprocess.check_output(['python-config','--libs']).strip()


class PICO():
    """ 
    A PICO class represents a mapping from input values to output values.
    
    Additionally, if the input values are scalars and the output values 
    are vectors, then the code in this library can be used to call the 
    PICO object from C/Fortran.
    
    The fundamental methods are inputs(), outputs(), and get().
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

    
    
    
    
    
""" This global dictionary holds loaded PICO objects so they are not garbage collected."""
_picostages = {}


def _version_ok(pico):
    """Checks for compatibility of a PICO datafile."""
    global _version
    mine = map(int,_version.split('.'))
    if '_version' in pico.__dict__: theirs = map(int,pico._version.split('.'))
    else: 
        print "Warning: PICO datafile does not have version. Can't check compatibility."
        return True
    return mine[:2]==theirs[:2] and mine[2]>=theirs[2]


def load_pico(datafile, module=None, check_version=True):
    """
    Load a PICO data datafile and return a PICO object.
    
    If module is not None, it can specify a path to a Python file, which will 
    be used instead of the code contained in the datafile. This is generally 
    used for debugging purposes only.
    """
    global _picostages
    
    try:
        with open(datafile) as f: code, data = cPickle.load(f)
    except Exception as e:
        raise Exception("Failed to open PICO datafile '%s'\n%s"%(datafile,e.message))
        
    if module==None:
        try:
            mymod = imp.new_module('picostage (%s)'%os.path.basename(datafile).replace('.','_'))
            exec code in mymod.__dict__
        except Exception as e:
            raise Exception("Error executing PICO code for datafile '%s'\n%s"%(datafile,e))
    else:
        sys.path.append(os.path.dirname(module))
        mymod = __import__(os.path.basename(module).replace('.py',''))
        reload(mymod)

    _picostages[mymod.__name__]=mymod
    
    if check_version and not _version_ok(mymod):
        raise Exception("Your PICO version is %s but this datafile was created using an incompatible older version, %s.")
    
    return mymod.get_pico(data)

    
def create_pico(data,codefile,datafile):
    """
    Create a PICO datafile.
    
    A PICO datafile is a Python Pickle of a length 2 tuple containing (code, data).
    
    Arguments:
        data - any Pickle-able Python object. 
        codefile - path to a module which has a get_pico(data) 
                   function which returns a PICO object.
        datafile - the output datafile
    """
    with open(codefile) as f: 
        code = re.sub("###(.|\n)*?###","",f.read())
        code += "\n_version='%s'"%_version
    with open(datafile,'w') as f: cPickle.dump([code,data],f)
    
    
