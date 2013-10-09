from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

setup(
   name='pypico',
   version='3.3.0',
   author='Marius Millea',
   author_email='mmillea@ucdavis.edu',
   packages=['pypico'],
   url='http://pypi.python.org/pypi/pypico/',
   license='LICENSE.txt',
   description='Quickly compute the CMB powerspectra and matter transfer functions.',
   long_description=open('README.rst').read(),
   cmdclass = {'build_ext':build_ext},
   ext_modules = [Extension("pypico.libpico",["pypico/pico.pyx"])]
)

#TODO: add these back
# config.add_data_files('plugins/camb/*')
# config.add_data_files('plugins/cosmomc/*')
