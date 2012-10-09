===============================================
PICO (Parameters for the Impatient Cosmologist)
===============================================

Installation
============

To install PICO, download and extract the archive, and from 
the top folder run::

    python setup.py build
    python setup.py install

or, to automatically download the archive and install PICO
in one command, run either of::

    easy_install pypico
    
or::

    pip install pypico
    
depending on which is available on your system.
    

Install notes
-------------
* If you don't have root access, you can append the option ``--user`` 
  to any of these install commands to install PICO under your home directory 
  instead of system wide.
    
  

Usage
=====   

Once you have PICO installed, to do anything you'll need some data files
which actually contain interpolated data. You can find them on 
the PICO website at `<https://sites.google.com/a/ucdavis.edu/pico/download>`_.

After that, PICO is used from the Python shell. Typical usage
starts by loading a PICO data file::

    >> import pypico
    >> pico = pypico.load_pico("example_pico_file.dat")  

To show accepted input parameters call::

    >> pico.inputs()
    
and to show outputted quantities call::

    >> pico.outputs()
    
Finally, to run PICO call::
  
    >> result = pico.get(outputs, **inputs)

where ``outputs`` is a list of outputs you actually want (or leave it unspecified 
to calculate all outputs), and ``**inputs`` is a dictionary of parameter 
values with keys for each input returned above. The return value ``result`` 
is a dictionary with a key corresponding to each output you requested. 
    
Usage Notes
-----------

* The PICO convention for multipole indexing is that an array entry ``arr[l]`` 
  corresponds to the l-th multiple. Since Python is 0-indexed, this means the 
  first entry in an array is the 0-th multiple. 
   
* The specification ``pico.get(outputs, **inputs)`` means ``get`` can be called
  in several ways, including::
  
    >> pico.get(param1=val1, params2=val2)
    >> pico.get(**{'param1':val1, 'param2':val2})
    >> pico.get(**dict(param1=val1, param2=val2))
    >> pico.get(param1=val1, **{'param2':val2})
    
      
* Certain data files may contain a set of example input values
  which can be accessed with::
  
    >> pico.example_inputs()
    



Installing Plugins for CAMB and CosmoMC
=======================================

Follow the instruction in this section if you'd like to,

* Have your code which currently calls ``CAMB_GetResults`` used PICO instead
* Have CosmoMC use PICO


Linking
-------

When you installed PICO, a static library ``libpico.a`` was created
which allows PICO to be called from C, C++, Fortran, or any other 
language which can understand the symbols in the library. To link 
your code against this library, PICO provides an easy way to get 
include and link flags on your platform. To print out the necessary flags, call::
    
    python -c "import pypico; print pypico.get_include()"
    python -c "import pypico; print pypico.get_link()"
    
You should put these calls directly in your Makefile via::

    $(shell python -c "import pypico; print pypico.get_link()")


Plugin Folder
-------------

You can find the various plugin files in a folder ``plugin`` in the archive.
If you installed PICO via ``pip`` or ``easy_install``, you can find the location
of the plugins by running::

    python -c "import pypico; print pypico.get_folder()"


CAMB Plugin
-----------

If your code is set up to call the CAMB function ``CAMB_GetResults``, then 
it should be trivial to use the PICO version called ``PICO_GetResults`` instead.
The PICO version will fall back on the CAMB version if called with parameters
for which it cannot calculate the relevant quantities. 

To install the CAMB plugin, do the following:

* Copy ``plugins/camb/pico_camb.f90`` to the folder containing your code
* In your Makefile, make sure ``pico_camb.f90`` gets compiled. 
* Add a call ``fpico_load(file)`` to load a PICO datafile.
* Replace ``CAMB_GetResults`` with ``PICO_GetResults``
* Add ``use pico_camb`` wherever you need ``PICO_GetResults``
* Compile your code, making sure to use the correct include/link flags (see `Linking`_).
* Add the key ``pico_datafile`` to your parameter file.



CosmoMC Plugin
--------------

PICO can also be plugged into CosmoMC. 

To install the CosmoMC plugin, do the following:

* Copy ``plugins/cosmomc/CMB_Cls_pico.f90`` and ``plugins/camb/pico_camb.f90`` 
  to the CosmoMC source folder
* Replace ``driver.f90`` in the CosmoMC source folder with the one in ``plugins/cosmomc``
* In your CosmoMC Makefile, add the line ``CMB_Cls_pico.o: pico_camb.o`` 
* In your CosmoMC Makefile, replace references to ``CMB_Cls_simple`` 
  with references to ``CMB_Cls_pico`` 
* Add the correct include/link flags to the Makefile (see `Linking`_).
* Add the key ``pico_datafile`` to your parameter file.



Known Issues
============

* ``-fast`` with Intel Fortran does not work
* The CosmoMC plugin does not support PICO datafiles which provide the WMAP likelihood. 


Authors
=======

The main author of PICO is Marius Millea (feel free to send questions/comments to mmillea@ucdavis.edu). 

PICO was originally created by Chad Fendt and Ben Wandelt (see `<http://arxiv.org/abs/0712.0194>`_) 




