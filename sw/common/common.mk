###############################################################################
# Makefile for creating lab assignments
#
# Authors: Michael Steffen (steffma@iastate.edu)
#          Joseph Zambreno (zambreno@iastate.edu)
#          Iowa State University
###############################################################################

.SUFFIXES : .c .o


# Directory setup
ROOTDIR 	:= "$(CDIR)/sw"
ROOTBINDIR 	:= $(ROOTDIR)/bin
ROOTUTILDIR     := "$(CDIR)/utils"
ROOTOBJDIR	:= ./obj
SRCDIR		:= ./
TARGET 	 	:= $(EXECUTABLE)

#Compilers
CC		:= gcc
CPP		:= g++
LINK		:= g++ 

# Includes
INCLUDE_PATH	+= -I. -I$(ROOTUTILDIR)/include/ -I$(ROOTDIR)/common/include/

# Libs
LIB_PATH	+= -L$(ROOTUTILDIR)/lib64/ -L$(ROOTDIR)/common/lib/


# Comp Flags
CFLAGS	+= -O2

# check if verbose 
ifeq ($(verbose), 0)
        VERBOSE := 
else
        VERBOSE := 
endif


###############################################################################
# Set up object files
###############################################################################
OBJDIR := $(ROOTOBJDIR)
OBJS +=  $(patsubst %.c,$(OBJDIR)/%.o,$(notdir $(CFILES)))
OBJS +=  $(patsubst %.cpp,$(OBJDIR)/%.cpp.o,$(notdir $(CPPFILES)))

LIB += -lglut -lGLU -lGL -lsimpleGLU 

LINKLINE = $(LINK) -o $(TARGET) $(OBJS) $(LIB_PATH) $(LIB)


##############################################################################
# Additional req files
##############################################################################
REQFILE := $(ROOTUTILDIR)/include/simple2D.h $(ROOTUTILDIR)/include/simpleGLU.h

###############################################################################
# Rules
###############################################################################
$(OBJDIR)/%.o : $(SRCDIR)%.c $(C_DEPS) #$(REQFILE)
	$(VERBOSE)$(CC) $(CFLAGS) $(INCLUDE_PATH) -o $@ -c $<

$(OBJDIR)/%.cpp.o : $(SRCDIR)%.cpp $(C_DEPS) #$(REQFILE)
	$(VERBOSE)$(CPP) $(CFLAGS) $(INCLUDE_PATH) -o $@ -c $<

$(TARGET): makedirectories $(OBJS) Makefile
	$(VERBOSE)$(LINKLINE)
	$(VERBOSE)cp $(TARGET) $(ROOTBINDIR)

#$(REQFILE):
#	make -C $(ROOTUTILDIR) all

makedirectories:
	$(VERBOSE)mkdir -p $(OBJDIR)
	$(VERBOSE)mkdir -p $(ROOTBINDIR)

clean:
	$(VERBOSE)rm -f *~
	$(VERBOSE)rm -rf $(OBJDIR)
	$(VERBOSE)rm -f $(TARGET)

distclean: clean
	$(VERBOSE)rm -f $(ROOTBINDIR)/$(EXECUTABLE)
