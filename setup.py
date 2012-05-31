from numpy.distutils.core import setup, Extension

setup(
    name='PICO',
    version='0.1.0',
    author='Marius Millea',
    author_email='mmillea@ucdavis.edu',
    packages=['pypico'],
    url='http://pypi.python.org/pypi/PICO/',
    license='LICENSE.txt',
    description='Quickly compute the CMB powerspectra and matter transfer functions.',
    long_description=open('README').read(),
    libraries = [('fpico', dict(sources=['pypico/fpico.f90']))],
    ext_modules=[Extension('pypico.libpico', ['pypico/cpico.c','pypico/fpico_cwrap.c'],libraries = ['fpico'])],
#    install_requires=[
#        "numpy >= 1.5.1",
#        "scipy == 0.9.0",
#    ],
)
