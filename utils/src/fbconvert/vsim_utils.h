/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * vsim_utils.h - utility functions for reading and writing to Modelsim memory
 * files.
 *
 *
 * NOTES:
 * 6/23/10 by JAZ::Design created.
 *****************************************************************************/



#ifndef _VSIM_UTIL_H_
#define _VSIM_UTIL_H_

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "fbconvert.h"


// Struct to hold the limited vsim file format metadata
struct vsim_file_info_s {
  char *comment;
  char *instance;
  char *flags;
}; typedef struct vsim_file_info_s vsim_file_info;


unsigned int **vsim_to_array(config_type *config, vsim_file_info *vsim);
void vsim_info(vsim_file_info *vsim);
void array_to_vsim(config_type *config, unsigned int **pixels, vsim_file_info *vsim);
void init_vsim(config_type *config, vsim_file_info *vsim);
//unsigned int **allocate_pixel_array(int width, int height);


#endif
