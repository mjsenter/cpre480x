CC   	= gcc
CFLAGS 	= -O2 -Wall
LDFLAGS = -lm

OBJ  	= fbconvert.o utils.o bmp_utils.o vsim_utils.o
EXEC  = fbconvert


all: $(EXEC)

$(EXEC): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	cp $(EXEC) ../../bin/


clean:
	rm -rf *~ *# core ../core *.o *.exe $(EXEC);
