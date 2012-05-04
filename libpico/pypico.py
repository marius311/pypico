_picostages = {}

def loadpico(datafile,module=None):
    """
    Loads a PICO data datafile and returns a function of parameters which
    returns powerspectra.
    """
    import imp, os, cPickle, sys
    global _picostages
    
    with open(datafile) as f: code, data = cPickle.load(f)
    if module==None:
        mymod = imp.new_module('picostage (%s)'%os.path.basename(datafile).replace('.','_'))
        exec code in mymod.__dict__
    else:
        sys.path.append(os.path.dirname(module))
        mymod = __import__(os.path.basename(module).replace('.py',''))
    _picostages[mymod.__name__]=mymod
    
    return mymod.getpico(data)
    
    
def createpico(data,codefile,datafile):
    """
    Create a PICO datafile by pickling together the code in codefile
    and the given data.
    """
    import re, cPickle
    with open(codefile) as f: codefile= re.sub("###(.|\n)*?###","",f.read())
    with open(datafile,'w') as f: cPickle.dump([codefile,data],f)
    
    
class CantUsePICO(Exception): pass