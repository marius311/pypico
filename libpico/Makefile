#Set your platform dependent variables in this file:
include Makefile.inc

default: libpico3.a

cpico.o: cpico.c
	$(CC) $(CFLAGS) $(PYTHONINC) $(NUMPYINC) -c  $? 

fpico_cwrap.o: fpico_cwrap.c
	$(CC) $(CFLAGS) $(PYTHONINC) $(NUMPYINC) -c  $?

fpico.o: fpico.f90
	$(F90C) $(FFLAGS) -I$(CAMBDIR) -c fpico.f90
	
libpico3.a: cpico.o fpico_cwrap.o fpico.o
	-rm -f libpico3.a
	ar r $@ cpico.o fpico_cwrap.o fpico.o

clean: 
	-rm -rf libpico3.a *.o *.mod
