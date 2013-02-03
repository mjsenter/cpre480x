/*
 * Iowa State University Simple 3-D Graphics Library Utility (simpleGLU)
 * Version: 0.1
 *
 * Created by: Michael Steffen (steffma@iastate.edu)
 *	       Joseph Zambreno (zambreno@iastate.edu)
 *
 */


#ifndef __sglu_h_
#define __sglu_h_

#ifdef __cplusplus
extern "C" {
#endif


#define SGLU_VERSION_0_1	  1


// API Functions
int sgluLoadBitmap( char *fileName, unsigned short *width, unsigned short *height, unsigned char **data);
int sgluLoadBitmapRGBA( char *fileName, unsigned short *width, unsigned short *height, unsigned char **data);

#ifdef __cplusplus
}
#endif

#endif	/* __sglu_h_ */

