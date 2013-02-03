
###############################################################################
# Makefile for creating static library for SGP common driver utils
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
LIBNAME		:= libSGPUtils.a
ROOTLIBDIR	:= ../../lib64
ROOTLIBDIR32	:= ../../lib
TARGET		:= $(ROOTLIBDIR)/$(LIBNAME)
TARGET32	:= $(ROOTLIBDIR32)/$(LIBNAME)


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

OBJFILES := $(ROOTOBJDIR)/transmit.o $(ROOTOBJDIR)/typeConv.o
OBJFILES32 := $(ROOTOBJDIR)/transmit.o.32 $(ROOTOBJDIR)/typeConv.o.32
SRCFILES := $(SOURCE)/transmit.c $(SOURCE)/typeConv.c

all: makedirectories $(SRCFILES) $(OBJFILES) $(OBJFILES32)
	$(VERBOSE)$(CLIB) $(TARGET) $(OBJFILES)
	$(VERBOSE)$(CLIB) $(TARGET32) $(OBJFILES32)
	$(VERBOSE)cp $(SOURCE)/sgp_driver_utils.h $(ROOTLIBDIR)/../include/sgp_driver_utils.h

#Compile all .c files
$(ROOTOBJDIR)/%.o : $(SOURCE)/%.c
	$(VERBOSE)$(CC) -fPIC -c $(INCLUDES) $(COMMONFLAGS) -o $@ $<

$(ROOTOBJDIR)/%.o.32 : $(SOURCE)/%.c
	$(VERBOSE)$(CC) -m32 -fPIC -c $(INCLUDES) $(COMMONFLAGS) -o $@ $<

clean:
	$(VERBOSE)rm -rf $(ROOTOBJDIR)
	$(VERBOSE)rm -f $(TARGET)
	$(VERBOSE)rm -f $(TARGET32)
	$(VERBOSE)rm -f $(ROOTLIBDIR)/../include/sgp_driver_utils.h

makedirectories:
	$(VERBOSE)mkdir -p $(ROOTOBJDIR)

