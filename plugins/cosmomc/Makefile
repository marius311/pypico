#These are the necessary changes to the CosmoMC Makefile

#The custom CMB_Cls file
CLSFILE = CMB_Cls_pico.o

#Extra include and link flags
INCLUDE += $(shell python -c "import pypico; print pypico.get_include()")
LINKFLAGS += $(shell python -c "import pypico; print pypico.get_link()")
