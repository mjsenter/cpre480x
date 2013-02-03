CC   	= gcc
CFLAGS 	= -O2 -Wall -I../../include
LDFLAGS = -L../../lib64 -lm -lSGPUtils

OBJ  	= sgbsimcp.o
EXEC  = sgbsimcp


%.o : %.c ../../lib64/libSGPUtils.a
	$(CC) $(CFLAGS) -o $@ -c $<

all:$(EXEC)

$(EXEC): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	cp $(EXEC) ../../bin/

../../lib64/libSGPUtils.a:
	make -C ../sgpDriverUtils all

clean:
	rm -rf *~ *# core ../core *.o *.exe $(EXEC);
