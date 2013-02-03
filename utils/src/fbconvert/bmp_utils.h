/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * bmp_utils.h - utility functions for reading and writing to bmp files.
 *
 *
 * NOTES:
 * 6/23/10 by JAZ::Design created.
 *****************************************************************************/



#ifndef _BMP_UTIL_H_
#define _BMP_UTIL_H_

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "fbconvert.h"


// The 2 byte magic number, as a separate struct to avoid
// alignment problems
struct bmp_magic_s {
  unsigned char magic[2];
}; typedef struct bmp_magic_s bmp_magic;

// File size and offset information
struct bmp_header_s {
  unsigned int filesz;
  unsigned short creator1;
  unsigned short creator2;
  unsigned int bmp_offset;
}; typedef struct bmp_header_s bmp_header;
 
// Bitmap information (assumes Windows V3 version)
struct dib_header_s {
  unsigned int header_sz;
  unsigned int width;
  unsigned int height;
  unsigned short nplanes;
  unsigned short bitspp;
  unsigned int compress_type;
  unsigned int bmp_bytesz;
  unsigned int hres;
  unsigned int vres;
  unsigned int ncolors;
  unsigned int nimpcolors;
}; typedef struct dib_header_s dib_header;

// Struct to hold all the metadata, including the color palette
struct bmp_file_info_s {
  bmp_magic *h1;
  bmp_header *h2;
  dib_header *h3;
  unsigned int *h4;
}; typedef struct bmp_file_info_s bmp_file_info;

unsigned int **bmp_to_array(config_type *config, bmp_file_info *bmp);
void bmp_info(bmp_file_info *bmp);
void array_to_bmp(config_type *config, unsigned int **pixels, bmp_file_info *bmp);
void init_bmp(config_type *config, bmp_file_info *bmp);
unsigned int **allocate_pixel_array(int width, int height);


#endif
