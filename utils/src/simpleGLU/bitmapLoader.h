#ifndef _BITMAP_H
#define _BITMAP_H
//File: bitmapLoader.h
//Written by:     Mark Bernard
//on GameDev.net: Captain Jester
//e-mail: mark.bernard@rogers.com
//Please feel free to use and abuse this code as much
//as you like.  But, please give me some credit for
//starting you off on the right track.
//
//The file bitmapLoader.cpp goes along with this file
//

const short BITMAP_MAGIC_NUMBER=19778;
const int RGB_BYTE_SIZE=3;
const int RGBA_BYTE_SIZE=4;

#pragma pack(push,bitmap_data,1)


// typdefs for main BMP headers ------------------
typedef struct tagRGBQuad {
	char rgbBlue;
	char rgbGreen;
	char rgbRed;
	char rgbReserved;
} RGBQuad;

// BMP headers --------------------------------------

typedef struct tagBitmapFileHeader {
	unsigned short bfType;
	unsigned int bfSize;
	unsigned short bfReserved1;
	unsigned short bfReserved2;
	unsigned int bfOffBits;
} BitmapFileHeader;

typedef struct tagBitmapInfoHeader {
	unsigned int biSize;
	int biWidth;
	int biHeight;
	unsigned short biPlanes;
	unsigned short biBitCount;
	unsigned int biCompression;
	unsigned int biSizeImage;
	int biXPelsPerMeter;
	int biYPelsPerMeter;
	unsigned int biClrUsed;
	unsigned int biClrImportant;
} BitmapInfoHeader;


typedef struct tagBITMAPV2INFOHEADER {
 	unsigned int bmiRedMask;
	unsigned int bmiGreenMask;
	unsigned int bmiBlueMask;
} BITMAPV2INFOHEADER;

typedef struct tagBITMAPV3INFOHEADER {
	unsigned int bmiAlphaMask;
} BITMAPV3INFOHEADER;





#pragma pack(pop,bitmap_data)


#endif //_BITMAP_H

