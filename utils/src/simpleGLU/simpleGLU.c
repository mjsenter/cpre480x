/*
 * Iowa State University Simple 3-D Graphics Library Utility (simpleGLU)
 * Version: 0.1
 *
 * Created by: Michael Steffen (steffma@iastate.edu)
 *             Joseph Zambreno (zambreno@iastate.edu)
 *
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "bitmapLoader.h"
#include "simpleGLU.h"


enum dataFormats_t { simpleGLU_ARGB, simpleGLU_RGBA };


// Helper Function for sgluLoadBitmap, Converts RGB format
int convert(   unsigned char* tempData,
		 unsigned int width,
		 unsigned int height,
		 int padWidth,
		 BITMAPV2INFOHEADER bmih2,
		 BITMAPV3INFOHEADER bmih3,
		 unsigned int dataSize,
		 unsigned short bitCount, 
		 int byteWidth,
		 unsigned char **data,
		 enum dataFormats_t dataFormat) {

	int offset,diff, step;
	unsigned int i,k;

	unsigned short offsets[4];
	unsigned short bits[4];
	float scaleFactor[4];
	unsigned int temp;
	unsigned int *p;

#define GETCNT( index, varName ) 	offsets[index] = 0;				\
					bits[index]=0;					\
					if(varName != 0) {				\
					  temp = varName;				\
					  while((temp & 0x01) != 0x01) {		\
						offsets[index]++;			\
			 	  		temp = temp >> 1;			\
        				  }						\
	        			  while((temp & 0x01) != 0x00) {		\
	   					bits[index]++;				\
		 	  			temp = temp >> 1;			\
	       		 		  }						\
					}

	GETCNT(0, bmih3.bmiAlphaMask)
	GETCNT(1, bmih2.bmiRedMask) 
	GETCNT(2, bmih2.bmiGreenMask)
	GETCNT(3, bmih2.bmiBlueMask)


	scaleFactor[0] = 255.0 / (pow(2, bits[0])-1);
	scaleFactor[1] = 255.0 / (pow(2, bits[1])-1);
	scaleFactor[2] = 255.0 / (pow(2, bits[2])-1);
	scaleFactor[3] = 255.0 / (pow(2, bits[3])-1);
#if 0
printf("A:  mask:0x%x, offsets: %d, bits: %d, scaleFactor: %f\n", bmih3.bmiAlphaMask, offsets[0], bits[0], scaleFactor[0]);
printf("R:  mask:0x%x, offsets: %d, bits: %d, scaleFactor: %f\n", bmih2.bmiRedMask, offsets[1], bits[1], scaleFactor[1]);
printf("G:  mask:0x%x, offsets: %d, bits: %d, scaleFactor: %f\n", bmih2.bmiGreenMask, offsets[2], bits[2], scaleFactor[2]);
printf("B:  mask:0x%x, offsets: %d, bits: %d, scaleFactor: %f\n", bmih2.bmiBlueMask, offsets[3], bits[3], scaleFactor[3]);
#endif
	diff=width*height*RGBA_BYTE_SIZE;

	//allocate the buffer for the final image data
    	*data = (unsigned char *) malloc(diff * sizeof(unsigned char));

    	//exit if there is not enough memory
    	if(*data==NULL) {
        	free(*data);
	        return -5;
    	}
    	if(height<=0) {
        	step=bitCount/8;
		offset = padWidth - byteWidth;
        	for(i=0,k=0;i<diff;i+=4,k+=step) {

			// if i is the start of a new row, k+=step
			if((i > 0) && ( (i % width)==0  )) {
			    k+=step;
			}

			p = (unsigned int*)(tempData+k);
			if(dataFormat == simpleGLU_RGBA) {
			    *((*data)+i+3) = (bits[0] == 0) ? 0xff: (unsigned char)((( *p >> offsets[0]) & ((1 << bits[0])-1)) * scaleFactor[0]);
                            *((*data)+i+0) = (unsigned char)((float)(( *p >> offsets[1]) & ((1 << bits[1])-1)) * scaleFactor[1]);
                            *((*data)+i+1) = (unsigned char)((float)(( *p >> offsets[2]) & ((1 << bits[2])-1)) * scaleFactor[2]);
                            *((*data)+i+2) = (unsigned char)((float)(( *p >> offsets[3]) & ((1 << bits[3])-1)) * scaleFactor[3]);
			} else {
			    *((*data)+i+0) = (bits[0] == 0) ? 0xff: (unsigned char)((( *p >> offsets[0]) & ((1 << bits[0])-1)) * scaleFactor[0]);
			    *((*data)+i+1) = (unsigned char)((float)(( *p >> offsets[1]) & ((1 << bits[1])-1)) * scaleFactor[1]);
			    *((*data)+i+2) = (unsigned char)((float)(( *p >> offsets[2]) & ((1 << bits[2])-1)) * scaleFactor[2]);
			    *((*data)+i+3) = (unsigned char)((float)(( *p >> offsets[3]) & ((1 << bits[3])-1)) * scaleFactor[3]);
		       }
        	}
    	}

    	//image parser for a forward image
    	else {
        	step=bitCount/8;
		offset = padWidth - byteWidth;
        	int j=dataSize-4;
        	//count backwards so you start at the front of the image
		//here you can start from the back of the file or the front,
		//after the header  The only problem is that some programs
		//will pad not only the data, but also the file size to
		//be divisible by 4 bytes.
		k=0;
		for(j=height-1;j>=0; j--) {
                    for(i=0;i<width;i++) {
			p = (unsigned int*)(tempData+k);
			if(dataFormat == simpleGLU_RGBA) {
			    *((*data)+(j*width+i)*4+3)=(bits[0] == 0) ? 0xff :  (unsigned char)((float)(( *p >> offsets[0]) & ((1 << bits[0])-1))*scaleFactor[0]);
                            *((*data)+(j*width+i)*4+0)= (unsigned char)((float)(( *p >> offsets[1]) & ((1 << bits[1])-1))*scaleFactor[1]);
                            *((*data)+(j*width+i)*4+1)= (unsigned char)((float)(( *p >> offsets[2]) & ((1 << bits[2])-1))*scaleFactor[2]);
                            *((*data)+(j*width+i)*4+2)= (unsigned char)((float)(( *p >> offsets[3]) & ((1 << bits[3])-1))*scaleFactor[3]);

                        } else {
			    *((*data)+(j*width+i)*4+0)=(bits[0] == 0) ? 0xff :  (unsigned char)((float)(( *p >> offsets[0]) & ((1 << bits[0])-1))*scaleFactor[0]);
                            *((*data)+(j*width+i)*4+1)= (unsigned char)((float)(( *p >> offsets[1]) & ((1 << bits[1])-1))*scaleFactor[1]);
                            *((*data)+(j*width+i)*4+2)= (unsigned char)((float)(( *p >> offsets[2]) & ((1 << bits[2])-1))*scaleFactor[2]);
                            *((*data)+(j*width+i)*4+3)= (unsigned char)((float)(( *p >> offsets[3]) & ((1 << bits[3])-1))*scaleFactor[3]);
			}
			k+=step;
		    }
		    //apply offset
		    k+=offset;
  		}

    	}

    return 0;

}

//--------------------------------------------------------------------------------------------------------
//
// Simple Graphics Library Utility Functions 
//
//--------------------------------------------------------------------------------------------------------

int loadBitmap( char *fileName, unsigned short *width, unsigned short *height, unsigned char **data, enum dataFormats_t dataFormat) {

	int i;
	
	FILE *in;			// file steam for reading
	unsigned char *tempData;			// temp storage for image data
	int numColors;			// total available colors
	BitmapFileHeader bmfh;		// Bitmap file header structure
	BitmapInfoHeader bmih;		// Bitmap info header structure
        BITMAPV2INFOHEADER bmih2;
	BITMAPV3INFOHEADER bmih3;
	unsigned int padding;		// bytes between header and image data
	unsigned char version;

	version = 0;

	// Open the file for reading in binary mode
	in = fopen(fileName, "rb");
	

	// if the file does not exist return an error
	if(in == NULL) {

		return -1;
	}


	//read in the entire BITMAPFILEHEADER
	fread(&bmfh,sizeof(BitmapFileHeader),1,in);

        // check and make sure that the header is the right size
	if ( sizeof(BitmapFileHeader) + sizeof(BitmapInfoHeader)  > bmfh.bfOffBits) {
            fclose(in);
            return -10;
        } 

	padding = bmfh.bfOffBits - (sizeof(BitmapFileHeader) + sizeof(BitmapInfoHeader));

	if(bmfh.bfType!=BITMAP_MAGIC_NUMBER) {
	        fclose(in);
	        return -2;
    	}

	//read in the entire BITMAPINFOHEADER
	fread(&bmih,sizeof(BitmapInfoHeader),1,in);
	version = 1;

	if(bmih.biBitCount < 16) {
	        fclose(in);
		return -3;
	}

	if(bmih.biPlanes != 1) {
		fclose(in);
		return -34;
	}

	if(bmih.biCompression!=0) {
	    if(bmih.biCompression!=3) {
		fclose(in);
		return -33;
	    }
	}

	*width = bmih.biWidth;
	*height = bmih.biHeight;
	

	// Check and see if we have a V2INFOHEADER
	if(padding >= sizeof(BITMAPV2INFOHEADER)) {
	     fread(&bmih2, sizeof(BITMAPV2INFOHEADER), 1, in);
	     padding -= sizeof(BITMAPV2INFOHEADER);
	     version = 2;
	}
        if((version == 1) || (bmih.biCompression==0)) {
	     if(bmih.biBitCount < 24) { 
                 bmih2.bmiRedMask = 0x00007c00;
                 bmih2.bmiGreenMask = 0x000003e0;
                 bmih2.bmiBlueMask = 0x0000001f;
             } else { 
	         bmih2.bmiRedMask = 0x00ff0000;
	         bmih2.bmiGreenMask = 0x0000ff00;
	         bmih2.bmiBlueMask = 0x000000ff;
            }
        }

        if((padding >= sizeof(BITMAPV3INFOHEADER)) && (version == 2)) {
	   fread(&bmih3, sizeof(BITMAPV3INFOHEADER),1,in);
	   padding -= sizeof(BITMAPV3INFOHEADER);
	   version = 3;
        }

	if((version == 2) || (bmih.biCompression==0)) {
	   if(bmih.biBitCount < 32) {
               bmih3.bmiAlphaMask = 0x00;
           } else {
	       bmih3.bmiAlphaMask = 0xff000000;
           }
	}
	
	// remove data between header and image data
	if(padding > 0) {
		tempData = (unsigned char*) malloc(padding * sizeof(unsigned char));
		if(tempData == NULL) {
			fclose(in);
			return -11;
		}
		fread(tempData, sizeof(unsigned char), padding, in);
		free(tempData);
	}

	//calculate the size of the image data with padding
	unsigned int dataSize = (bmih.biWidth*bmih.biHeight*(unsigned int)(bmih.biBitCount/8.0));

	//set up the temporary buffer for the image data
	tempData = (unsigned char*) malloc(dataSize * sizeof(unsigned char));

	// exit if there is not enough memory
	if(tempData==NULL) {
	        fclose(in);
	        return -4;
	}


	//read in the entire image
	fread(tempData,sizeof(char),dataSize,in);

	//close the file now that we have all the info
	fclose(in);	

	//calculate the witdh of the final image in bytes
	int byteWidth = (int)((float)bmih.biWidth*(float)bmih.biBitCount/8.0);
	int padWidth = byteWidth;

	//adjust the width for padding as necessary
    	while(padWidth%4!=0) {
        	padWidth++;
	}

	//change format from colorMasks to RGB
        int errorCode;
    	errorCode = convert(tempData, bmih.biWidth, bmih.biHeight, padWidth, bmih2, bmih3, dataSize, bmih.biBitCount, byteWidth, data, dataFormat);
        if(errorCode < 0) {
            return errorCode;
        }


	// Free temporary memory
	free(tempData);

	return bmih.biBitCount;
}


int sgluLoadBitmapRGBA( char *fileName, unsigned short *width, unsigned short *height, unsigned char **data) {
   loadBitmap(fileName, width, height, data, simpleGLU_RGBA);
}

int sgluLoadBitmap( char *fileName, unsigned short *width, unsigned short *height, unsigned char **data) {
   loadBitmap(fileName, width, height, data, simpleGLU_ARGB);
}


#if 0
// Math Operations
void sgluMultiply(float *A, float *B, float *Results) {
    unsigned int i,j,k;

    for(i = 0; i < 4; i++) {
        for(j = 0; j < 4; j++) {
            Results[i*4+j] = 0.0f;
            for(k = 0; k < 4; k++) {
                Results[i*4+j] += A[k*4+j]*B[i*4+k];
            }
        }
    }
}

// Transformations

void sgluLoadIdentity(float *m) {
    float tm[16] = {1.0f, 0.0f, 0.0f, 0.0f,
                    0.0f, 1.0f, 0.0f, 0.0f,
                    0.0f, 0.0f, 1.0f, 0.0f,
                    0.0f, 0.0f, 0.0f, 1.0f};
    memcpy(m, tm, sizeof(float) * 16);
} 

void sgluScale(float x, float y, float z, float *m) {
    float tmp_a[16];
    float tmp_b[16] = {    x, 0.0f, 0.0f, 0.0f,
                        0.0f,    y, 0.0f, 0.0f,
                        0.0f, 0.0f,    z, 0.0f,
                        0.0f, 0.0f, 0.0f, 1.0f};
    memcpy(tmp_a, m, sizeof(float) * 16);
    sgluMultiply(tmp_a, tmp_b, m);
}

void sgluTranslate(float x, float y, float z, float *m) {
    float tmp_a[16];
    float tmp_b[16] = { 1.0f, 0.0f, 0.0f, 0.0f,
                        0.0f, 1.0f, 0.0f, 0.0f,
                        0.0f, 0.0f, 1.0f, 0.0f,
                           x,    y,    z, 1.0f};
    memcpy(tmp_a, m, sizeof(float) * 16);
    sgluMultiply(tmp_a, tmp_b, m);
}

void sgluRotate( float angle_deg, float x, float y, float z, float *m) {
    float tmp_a[16];
    float angle_rad = angle_deg * M_PI / 180.0f;
    float tmp_b[16] = { cos(angle_rad)+(1-cos(angle_rad))*x*x, (1-cos(angle_rad))*x*y + z*sin(angle_rad), (1-cos(angle_rad))*x*z-y*sin(angle_rad), 0.0f,
                        (1-cos(angle_rad))*x*y - z*sin(angle_rad), cos(angle_rad)+(1-cos(angle_rad))*y*y, (1-cos(angle_rad))*y*z+x*sin(angle_rad), 0.0f,
                        (1-cos(angle_rad))*x*z + y*sin(angle_rad), (1-cos(angle_rad))*y*z - x*sin(angle_rad), cos(angle_rad) + (1-cos(angle_rad))*z*z, 0.0f,
                                       0.0f,                               0.0f,                                        0.0f,                         1.0f};

    memcpy(tmp_a, m, sizeof(float) * 16);
    sgluMultiply(tmp_a, tmp_b, m);

}
#endif
