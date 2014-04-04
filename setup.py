from numpy.distutils.core import setup
from numpy.distutils.misc_util import Configuration
from distutils.sysconfig import get_python_inc
import sys


# By default don't try to use Cython to compile the pyx file,
# just use the distributed C file.
build_cython=('--build_cython' in sys.argv)
if build_cython:
   sys.argv.remove('--build_cython')
   from Cython.Compiler.Main import compile
   compile('pypico/pico.pyx')


config = Configuration('pypico',
   name='pypico',
   version='3.3.0',
   author='Marius Millea',
   author_email='mmillea@ucdavis.edu',
   packages=['pypico'],
   url='http://pypi.python.org/pypi/pypico/',
   license='LICENSE.txt',
   description='Quickly compute the CMB powerspectra and matter transfer functions.',
   long_description=open('README.rst').read(),
)


# Compile libpico.a
config.add_installed_library('pico',
                             ['pypico/pico.c'],
                             'pypico',
                             {'include_dirs':[get_python_inc()]})


# Other files
config.add_data_files(('','pypico/fpico_interface.f90'))
config.add_data_files(('','pypico/pico.h'))
config.add_data_files('plugins/camb/*')
config.add_data_files('plugins/cosmomc/*')


setup(**config.todict())
