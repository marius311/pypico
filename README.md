# PICO (Parameters for the Impatient Cosmologist)

PICO computes Cosmic Microwave Background power spectra and matter transfer functions orders of magnitude faster than [CAMB](https://camb.info/) or [CLASS](https://class-code.net/). It does so by fitting an interpolating function to various training data (much of this training data is computed by volunteers at [Cosmology@Home](https://www.cosmologyathome.org)). This is accurate enough for parameter estimation from Planck satellite data. 

The original PICO was described in https://arxiv.org/abs/astro-ph/0606709 and https://arxiv.org/abs/0712.0194, although only the very basic idea of those papers remain in the current version. No updated paper exists, however, so please cite those papers if you are using PICO. Feel free to file an [Issue](https://github.com/marius311/pypico/issues) if you find bugs or need any help.


## Installation

You can install PICO via Pip:

```
pip install git+https://github.com/marius311/pypico [--user] [--upgrade]
```

or you can install from source by cloning this repostory and running:

```
git clone https://github.com/marius311/pypico
cd pypico
python setup.py build
python setup.py install [--user]
```


### Install notes

* If you don't have root access, the `--user` option installs PICO in your home directly.
* The `--upgrade` option forces the newest version to be installed. 

### Requirements

* Python 3.X
* NumPy (>=1.6.1)
* SciPy (>=0.10.1)


## Usage

Once you have PICO installed, to do anything you'll need some data files which actually contain interpolated data. You can find them [here](https://github.com/marius311/pypico-trainer/releases). 

After that, PICO is used from the Python shell. Typical usage starts by loading a PICO data file:

```python
>> import pypico
>> pico = pypico.load_pico("example_pico_file.dat")  
```

To show accepted input parameters call:

```python
>> pico.inputs()
```

and to show outputted quantities call:

```python
>> pico.outputs()
```
  
Finally, to run PICO call:
  
```python
>> result = pico.get(outputs, **inputs)
```

where `outputs` is a list of outputs you actually want (or leave it unspecified to calculate all outputs), and `**inputs` is a dictionary of parameter values with keys for each input returned above. The return value `result` is a dictionary with a key corresponding to each output you requested. 
    
## Usage Notes

* Each PICO datafile is trained on a particular region of parameter space, generally one large enough to be relevant for typical analyses. If PICO is called for a set of parameters outside this range, a `CantUsePICO` error will be raised, and you should use CAMB instead. If you are running an MCMC chain, this can slow you down significantly before the chain is burned in. To remedy this, set `force=True` to force PICO to return results even outside its training region. The results won't be guaranteed to be accurate, but will likely be good enough to get your chain to converge to the region where PICO is accurate. 

* The PICO convention for multipole indexing is that an array entry `arr[l]` corresponds to the l-th multiple. Since Python is 0-indexed, this means the first entry in an array is the 0-th multiple. 
   
* The specification `pico.get(outputs, **inputs)` means `get` can be called in several ways, including
     
    ```python
    >> pico.get(param1=val1, params2=val2)
    >> pico.get(**{'param1':val1, 'param2':val2})
    >> pico.get(**dict(param1=val1, param2=val2))
    >> pico.get(param1=val1, **{'param2':val2})
    ```
      
* Certain data files may contain a set of example input values which can be accessed with:
  
    ```python
    pico.example_inputs()
    ```



## Calling PICO from C/C++/Fortran

PICO can be called from C/C++ and Fortran. 

### C/C++ Interface

To call PICO from C/C++, you should include the following two header files:

```cpp
#include <python.h>
#include "pico.h"
```

Documentation for the functions defined in `pico.h` can be found in the `pico.pyx` file.

### Fortran Interface

To call PICO from Fortran, you should use the following module:

```fortran
use fpico
```

Documentation for the functions in the fpico module can be found in the `fpico_interface.f90` file. 

* Note that the Fortran interface is built on C, and to ensure integer/real byte-sizes are the same between Fortran and C, independent of compiler, they are defined by hand as `fpreal` and `fpint` in `fpico_interface.f90` and `pico.pyx`.


### Compiling and Linking

When you installed PICO, a static library `libpico.a` was created. To link your code against this library, PICO provides an easy way to get include and link flags on your platform. To print out the necessary flags, call:

```sh     
python -c "import pypico; print(pypico.get_include())"
python -c "import pypico; print(pypico.get_link())"
```
    
You should put these calls directly in your Makefile via:

```makefile
$(shell python -c "import pypico; print(pypico.get_link())")
```


The fortran interface file `fpico_interface.f90` should be recompiled each time along side your program, as it must use the same Fortran compiler. The location of this file can be accessed from your Makefile via:

```makefile
$(shell python -c "import pypico; print(pypico.get_folder())")/fpico_interface.f90
```


## Using PICO with CosmoMC

As of Apr 2014, partial PICO support is built into CosmoMC. See http://cosmologist.info/cosmomc/ for instructions.


## Using PICO in place of CAMB

If you have a code which currently calls `CAMB_GetResults`, its easy to swap in `PICO_GetResults` which uses PICO instead (and falls back on the CAMB version for parameters ouside of the PICO training region).

To install the CAMB plugin:

* Copy `plugins/camb/pico_camb.f90` to the folder containing your code
* In your Makefile, make sure `pico_camb.f90` gets compiled and `pico_camb.o` gets included in your executable.
* Add a call `fpico_load(file)` to load a PICO datafile.
* Replace `CAMB_GetResults` with `PICO_GetResults`
* Add `use pico_camb` wherever you need `PICO_GetResults`
* Compile your code, making sure to use the correct include/link flags (see `Compiling and Linking`_).


## Known Issues

* `-fast` with Intel Fortran does not work in some cases. 


## Authors

PICO is written by [Marius Millea](https://cosmicmar.com). The CosmoMC plugin was largely written by Antony Lewis and Silvia Galli. PICO was originally created by Chad Fendt and Ben Wandelt.
