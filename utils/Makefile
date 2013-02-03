###############################################################################
# Makefile for creating all utilities and librarires
#
# Authors: Michael Steffen (steffma@iastate.edu)
#          Joseph Zambreno (zambreno@iastate.edu)
#          Iowa State University
###############################################################################


PROJECTS := $(shell find src -name Makefile)
LIBTOPDIR := ../utils


%.ph_build : lib/libSGPUtils.a
	make -C $(dir $*) $(MAKECMDGOALS)

%.ph_clean : 
	make -C $(dir $*) clean $(USE_DEVICE)


all: $(addsuffix .ph_build,$(PROJECTS))
	@echo "Finished building all projects"

lib/libSGPUtils.a :
	make -C src/sgpDriverUtils $(MAKECMDGOALS)

clean: $(addsuffix .ph_clean,$(PROJECTS))
	@echo "Cleaned all projects" 

