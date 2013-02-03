###############################################################################
# Makefile for creating simple graphics library (simpleGL)
#
# Authors: Michael Steffen (steffma@iastate.edu)
#	   Joseph Zambreno (zambreno@iastate.edu)
# 	   Iowa State University
###############################################################################
# Variable definition

#----------------
# suffix rules
#----------------
.SUFFIXES: .o .c


#Library Name
LIBNAME		:= libsimpleGLU.a
ROOTLIBDIR	:= ../../lib64
TARGET		:= $(ROOTLIBDIR)/$(LIBNAME)


#Path to source files
SOURCE 	:= ./
ROOTOBJDIR := $(SOURCE)/build

# Compilers/Linkers
CC	:= gcc
LINK	:= gcc
CLIB	:= ar rcs

# Arguments
COMMONFLAGS	+= -O3

INCLUDES 	:= -I. -I$(ROOTLIBDIR)/../include

#check if verbose
ifeq ($(verbose),1)
	VERBOSE :=
else
	VERBOSE := 
endif

OBJFILES := $(ROOTOBJDIR)/simpleGLU.o
SRCFILES := $(SOURCE)/simpleGLU.c

all: makedirectories $(OBJFILES)
	$(VERBOSE)$(CLIB) $(TARGET) $(OBJFILES)
	$(VERBOSE)cp $(SOURCE)/simpleGLU.h $(ROOTLIBDIR)/../include/simpleGLU.h

#Compile all .c files
$(OBJFILES):$(SRCFILES)
	$(VERBOSE)$(CC) -c $(INCLUDES) $(COMMONFLAGS) -o $@ $<

clean:
	$(VERBOSE)rm -rf $(ROOTOBJDIR)
	$(VERBOSE)rm -f $(TARGET)
	$(VERBOSE)rm -f $(ROOTLIBDIR)/../include/simpleGLU.h

makedirectories:
	$(VERBOSE)mkdir -p $(ROOTOBJDIR)

