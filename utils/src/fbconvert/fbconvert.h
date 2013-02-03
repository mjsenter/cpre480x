/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/


/*****************************************************************************
 * fbconvert.h - fbconvert application - takes as input a Modelsim waveform 
 * file for a framebuffer module, and generates an equivalent bmp file for 
 * viewing. Can also perform the reverse operation.
 *
 *
 * NOTES:
 * 6/23/10 by JAZ::Design created.
 *****************************************************************************/



#ifndef _FBCONVERT_H_
#define _FBCONVERT_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define EXEC_NAME "fbconvert"


#define ERR_USAGE 1
#define ERR_NOFILE1 2
#define ERR_BADFILE 3
#define ERR_NOMEM 4
#define ERR_NOFILE2 5
#define ERR_BADHEIGHT 6
#define ERR_BADWIDTH 7
#define ERR_BADDEPTH 8
#define ERR_BADDEBUG 9
#define ERR_UNDEFINED 100

#define WIDTH_DEFAULT 800
#define HEIGHT_DEFAULT 600
#define DEPTH_DEFAULT 24
#define DEBUG_DEFAULT 10
#define OUTFILE_DEFAULT1 "output.bmp"
#define OUTFILE_DEFAULT2 "output.mem"

#define WIDTH_MIN 320
#define WIDTH_MAX 2560
#define HEIGHT_MIN 240
#define HEIGHT_MAX 2048


/* Structure to hold configuration information */
struct config_type_s {
  int height;
  int width;
  int depth;
  int debug_level;
  int reverse;
  char *infile_name;
  char *outfile_name;
  FILE *infile;
  FILE *outfile;
}; typedef struct config_type_s config_type;


/* Function prototypes (WebRank.c) */
config_type *init_config();
void check_config(config_type *);
void print_config(config_type *);


/* Function prototypes (utils.c) */
void print_help();
void raise_error(config_type *, int);
void read_command_line(config_type *, int, char **);

#endif /* _FBCONVERT_H_ */
