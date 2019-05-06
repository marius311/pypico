import sys
from distutils.sysconfig import get_python_inc
from distutils.version import StrictVersion

#Do some version checking
skip_version_check=('--skip_version_check' in sys.argv)
if skip_version_check:
    sys.argv.remove('--skip_version_check')
else:
    skipmsg = "Run with --skip_version_check to suppress this error (PICO may not work correctly)."
    if (sys.version_info < (3,)):
        raise Exception("PICO requires Python version 3.X. "+skipmsg)
    def checklib(lib,name,version):
      try:
          mod = __import__(lib)
          if StrictVersion(mod.__version__) < StrictVersion(version):
              raise Exception("PICO requires %s (>=%s). You have %s. "%(name,version,mod.__version__)+skipmsg)
      except ImportError:
          raise Exception("PICO requires %s. "%name+skipmsg)
    checklib('numpy','NumPy','1.6.1')
    checklib('scipy','SciPy','0.10.1')


from numpy.distutils.core import setup
from numpy.distutils.misc_util import Configuration


# By default don't try to use Cython to compile the pyx file,
# just use the file distributed with pypico. 
build_cython=('--build_cython' in sys.argv)
if build_cython:
    sys.argv.remove('--build_cython')
    from Cython.Compiler.Main import compile
    compile('pypico/pico.pyx')



config = Configuration('pypico',
    name='pypico',
    version='4.0.0',
    author='Marius Millea',
    author_email='mariusmillea@gmail.com',
    packages=['pypico'],
    url='https://github.com/marius311/pypico',
    license='LICENSE.txt',
    description='Quickly compute the CMB powerspectra and matter transfer functions.',
    long_description=open('README.md').read()
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
config.add_data_files('README.md')


setup(**config.todict())
