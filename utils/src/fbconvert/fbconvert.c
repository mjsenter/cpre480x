/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * fbconvert.c - fbconvert application - takes as input a Modelsim waveform 
 * file for a framebuffer module, and generates an equivalent bmp file for 
 * viewing. Can also perform the reverse operation. 
 *
 *
 * NOTES:
 * 6/23/10 by JAZ::Design created.
 *****************************************************************************/


#include <stdio.h>
#include <stdlib.h>

#include "fbconvert.h"
#include "bmp_utils.h"
#include "vsim_utils.h"

int main(int argc, char **argv) {

  bmp_file_info bmp;
  vsim_file_info vsim;
  config_type *config;

  unsigned int **pixels;


  /* Initialize the configuration datatype using default values */
  config = init_config();
  
  /* Parse the command line and modify configuration info if necessary */
  read_command_line(config, argc, argv);

  /* Check to see that the values are valid */
  check_config(config);
  
  /* If the debug level > 0 then print out the configuration information */
  if (config->debug_level > 0) {
    print_config(config);
  }


  // Standard operation is Modelsim --> bmp
  if (config->reverse == 0) {

    // Read from the Modelsim wave file and store the data as a 2D array
    pixels = vsim_to_array(config, &vsim);

    if (config->debug_level > 0) {
      vsim_info(&vsim);
    }

    // Dump the results back to a file
    init_bmp(config, &bmp);
    array_to_bmp(config, pixels, &bmp);

  }
  
  else {

    pixels = bmp_to_array(config, &bmp);

    if (config->debug_level > 0) {
      bmp_info(&bmp);
    }

    // Dump the results back to a file
    init_vsim(config, &vsim);
    array_to_vsim(config, pixels, &vsim);

  }
    
  return 0;
}


/*****************************************************************************
 * Function: init_config                                    
 * Description: Allocates memory for and initializes the configuration 
 * datatype using the default values
 *****************************************************************************/
config_type *init_config() {
  config_type *config;

  /* Allocate memory for the configuration datatype */
  config = (config_type *)malloc(sizeof(config_type));
  if (!config) {
    raise_error(config, ERR_NOMEM);
  }

  /* Set everything to its default value */
  config->height = HEIGHT_DEFAULT;
  config->width = WIDTH_DEFAULT;
  config->depth = DEPTH_DEFAULT;
  config->debug_level = DEBUG_DEFAULT;
  config->reverse = 0;
  config->infile_name = NULL;
  
  /* Allocate space for the output file name, even though we might need more
   * or less space after parsing the command line arguments. */
  config->outfile_name = (char *)malloc(strlen(OUTFILE_DEFAULT1)+1);
  if (!config->outfile_name) {
    raise_error(config, ERR_NOMEM);
  }
  strcpy(config->outfile_name, OUTFILE_DEFAULT1);

  config->infile = NULL;
  config->outfile = NULL;

  return config;
}



/*****************************************************************************
 * Function: check_config                                    
 * Description: Checks to make sure that the configuration values are valid.
 *****************************************************************************/
void check_config(config_type *config) {

  /* Value of width must be between WIDTH_MIN and WIDTH_MAX */
  if ((config->width < WIDTH_MIN) || (config->width > WIDTH_MAX)) {
    raise_error(config, ERR_BADWIDTH);
  }

  /* Value of height must be between HEIGHT_MIN and HEIGHT_MAX */
  if ((config->height < HEIGHT_MIN) || (config->height > HEIGHT_MAX)) {
    raise_error(config, ERR_BADHEIGHT);
  }

  /* Color depth should be 1, 4, 8, 16, 24, or 32 */
  if ((config->depth != 1) && (config->depth != 4) && (config->depth != 8) && 
      (config->depth != 16) && (config->depth != 24) && 
      (config->depth != 32)) {
    raise_error(config, ERR_BADDEPTH);
  }

  /* Value of debug_level should be > 0 */
  if (config->debug_level < 0) {
    raise_error(config, ERR_BADDEBUG);
  }
  
  return;
}



/*****************************************************************************
 * Function: print_config                                    
 * Description: Prints the configuration information for debug purposes.
 *****************************************************************************/
void print_config(config_type *config) {

  fprintf(stderr, "Printing (%s) configuration information:\n", EXEC_NAME);
  fprintf(stderr, "   width         - %d\n", config->width);
  fprintf(stderr, "   height        - %d\n", config->height);  
  fprintf(stderr, "   depth         - %d\n", config->depth);
  fprintf(stderr, "   debug_level   - %d\n", config->debug_level);
  fprintf(stderr, "   reverse       - %d\n", config->reverse);
  fprintf(stderr, "   infile_name   - %s\n", config->infile_name);
  fprintf(stderr, "   outfile_name  - %s\n", config->outfile_name);

  
  return;
}

