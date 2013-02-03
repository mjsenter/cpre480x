###############################################################################
# Makefile for creating all user applications
#
# Authors: Michael Steffen (steffma@iastate.edu)
#          Joseph Zambreno (zambreno@iastate.edu)
#          Iowa State University
###############################################################################


PROJECTS := $(shell find src -name Makefile)
LIBTOPDIR := ../utils


%.ph_build : 
	make -C $(dir $*) $(MAKECMDGOALS)

%.ph_clean : 
	make -C $(dir $*) clean $(USE_DEVICE)


all: $(addsuffix .ph_build,$(PROJECTS))
	@echo "Finished building all projects"


clean: $(addsuffix .ph_clean,$(PROJECTS))
	@echo "Cleaned all projects" 


