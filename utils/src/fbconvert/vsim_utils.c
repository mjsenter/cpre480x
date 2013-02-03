/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * vsim_utils.c - utility functions for reading and writing to Modelsim memory 
 * value files.
 *
 *
 * NOTES:
 * 6/23/10 by JAZ::Design created.
 *****************************************************************************/

#include "vsim_utils.h"
#include "bmp_utils.h"
#include "fbconvert.h"

/*****************************************************************************
 * Function: vsim_to_array                            
 * Description: Converts a modelsim memory value file to an equivalent 
 * 2D array of integer values representing pixels.
 *****************************************************************************/
unsigned int **vsim_to_array(config_type *config, vsim_file_info *vsim) {

  int twidth, theight, i, j;
  unsigned int **pixels;

  // Open up the file, and read the header information
  config->infile = fopen(config->infile_name, "r"); 
  if (!config->infile) {
    raise_error(config,ERR_NOFILE1);
  }

  // Allocate memory for the vsim_file_info variable
  vsim->comment = (char *)calloc(1024, 1);
  vsim->instance = (char *)calloc(1024, 1);
  vsim->flags = (char *)calloc(1024, 1);


  if ((!vsim->comment) || (!vsim->instance) || (!vsim->flags)) {
    raise_error(config, ERR_NOMEM);
  }
  
  if (config->debug_level > 3) {
    fprintf(stderr, "Reading vsim header information from %s\n", 
	    	    config->infile_name);
  }

  // Ideally we should be parsing the .mem file format, but it doesn't
  // seem likely we will be modifying it in any case
  fgets(vsim->comment, 1024, config->infile);
  fgets(vsim->instance, 1024, config->infile);
  fgets(vsim->flags, 1024, config->infile);

  twidth = config->width;
  theight = config->height;
 

  // Allocate memory for the 2D array
  pixels = allocate_pixel_array(twidth, theight);

  for (i = 0; i < theight; i++) {
    for (j = 0; j < twidth; j++) {
      fscanf(config->infile, "%x", &pixels[i][j]);
    }
  }


  fclose(config->infile);
 
  return pixels;
}

/*****************************************************************************
 * Function: vsim_info                            
 * Description: Prints out the Modelsim .mem header
 *****************************************************************************/
void vsim_info(vsim_file_info *vsim) {

  printf("Printing vsim file information:\n");
  printf("   %s", vsim->instance);
  printf("   %s", vsim->flags);

  return;
}


/*****************************************************************************
 * Function: array_to_vsim                            
 * Description: Converts a 2D array of pixels to a Modelsim memory file format
 *****************************************************************************/
void array_to_vsim(config_type *config, unsigned int **pixels, vsim_file_info *vsim) {


  int theight, twidth, nchars, i, j;

  config->outfile = fopen(config->outfile_name, "w");
  if (!config->outfile) {
    raise_error(config, ERR_NOFILE2);
  }


  if (config->debug_level > 3) {
    fprintf(stderr, "Writing vsim header information to %s\n", 
	    config->outfile_name);
  }  
  

  fprintf(config->outfile, "%s", vsim->comment);
  fprintf(config->outfile, "%s", vsim->instance);
  fprintf(config->outfile, "%s", vsim->flags);

  twidth = config->width;
  theight = config->height;

  nchars = (int)ceil(config->depth / 4);
  for (i = 0; i < theight; i++) {
    for (j = 0; j < twidth; j++) {
      fprintf(config->outfile, "%*x\n", nchars, pixels[i][j]);
    }
  }

  fclose(config->outfile);
  return;
}


/*****************************************************************************
 * Function: init_vsim                            
 * Description: Initializes a Modelsim .mem data structure
 *****************************************************************************/
void init_vsim(config_type *config, vsim_file_info *vsim) {


  // You might have to change this output manually

  // Allocate memory for the vsim_file_info variable
  vsim->comment = (char *)calloc(1024, 1);
  vsim->instance = (char *)calloc(1024, 1);
  vsim->flags = (char *)calloc(1024, 1);


  if ((!vsim->comment) || (!vsim->instance) || (!vsim->flags)) {
    raise_error(config, ERR_NOMEM);
  }

  strcpy(vsim->comment, "// memory data file (do not edit the following line - required for mem load use)\n");
  strcpy(vsim->instance, "// instance=/fb_dualport/ram\n");
  strcpy(vsim->flags, "// format=hex addressradix=h dataradix=h version=1.0 wordsperline=1 noaddress\n");


  return;
}
