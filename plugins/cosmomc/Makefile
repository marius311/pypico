#These are the necessary changes to the CosmoMC Makefile

PICODIR = 

INCLUDEPICO = -I$(PICODIR)
LINKPICO = -L$(PICODIR) -lpico3 $(shell python-config --ldflags)
INCLUDE = $(INCLUDEPICO)

CLSFILE = CMB_Cls_pico.o

LINKFLAGS = -L../camb -lcamb $(LAPACKL) $(LINKPICO)
