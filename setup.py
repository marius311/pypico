from numpy.distutils.core import setup, Extension
from numpy.distutils.misc_util import Configuration
from distutils.sysconfig import get_python_inc

config = Configuration('pypico',
   name='pypico',
   version='3.1.0',
   author='Marius Millea',
   author_email='mmillea@ucdavis.edu',
   packages=['pypico'],
   url='http://pypi.python.org/pypi/pypico/',
   license='LICENSE.txt',
   description='Quickly compute the CMB powerspectra and matter transfer functions.',
   long_description=open('README').read(),
)

config.add_installed_library('pico', 
                             ['pypico/fpico.f90','pypico/cpico.c','pypico/fpico_cwrap.c'],
                             'pypico',
                             {'include_dirs':[get_python_inc()]})

config.add_data_files('plugins/camb/*')
config.add_data_files('plugins/cosmomc/*')


setup(**config.todict())
