/* -----------------------------------------------------------------------
 * Mike Steffen    (steffma@iastate.edu)  
 * Joseph Zambreno (zambreno@iastate.edu)
 * Iowa State University
*/

#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <assert.h>

#include "simple2D.h"
#include "sgp_driver_utils.h"
#include "sgp.h"
#include "gltrace.h"


unsigned int *simMemory=NULL;

#define CHECK_INIT()  if(simMemory==NULL) { simMemory=(unsigned int*) malloc(67108864 * sizeof(unsigned int)); }

void simClear(unsigned int color) {
    CHECK_INIT();
    
    unsigned int i,j;

    for(i=0; i < 1024; i++) {
       for(j=0; j<1280;j++) {
          simMemory[i*2048+j] = color;
       }
    }

}
    

void createSprite( unsigned int sgp_address, unsigned char *dataSource, unsigned int width, unsigned int height ) {

    CHECK_INIT();

    unsigned int i,x,y,value;

    // send data to SGP
    SGPSendPacket( MEMCPY | TWO_D | HOST_TO_SGP_MEMORY | NUMPACKETS((width*height)+2) , 0, config );
    SGPSendPacket( sgp_address , 0, config );
    SGPSendPacket( DIM_X(width) | DIM_Y(height), 0 , config );


    for(i = 0; i < width * height*4; i+=4) {
 
        value =   ((dataSource[i+0] << 24) & 0xff000000)
                | ((dataSource[i+1] << 16) & 0x00ff0000)
                | ((dataSource[i+2] <<  8) & 0x0000ff00)
                | ((dataSource[i+3]      ) & 0x000000ff);

        SGPSendPacket( value, 0,config );


        y = (i/4)/width;
        x = (i/4) - (y*width);
        simMemory[sgp_address + y*2048 + x] = value;
    }

}

void SGPMemSet( unsigned int sgp_address, unsigned int value, unsigned int width, unsigned int height ) {
    
    CHECK_INIT();

    unsigned int i, j, k, l;

    SGPSendPacket( MEMSET | TWO_D | NUMPACKETS(3), 0,config);
    SGPSendPacket( sgp_address , 0,config);
    SGPSendPacket( DIM_X(width) | DIM_Y(height) ,0, config );
    SGPSendPacket( value , 0,config );

    GLV.glMatrixMode(GL_MODELVIEW);
    GLV.glPushMatrix();
    GLV.glLoadIdentity();
    for(i=sgp_address,j=0; j < height; j++, i+=2048 ) {
	GLV.glRasterPos2d(i % 2048, i / 2048);
        for(k=i,l=0; l < width; l++, k++) {
            simMemory[k] = value;
        }
        GLV.glDrawPixels(width, 1, GL_BGRA, GL_UNSIGNED_BYTE, &simMemory[i]);
    }
    GLV.glPopMatrix();

}

void SGPMemCpy( unsigned int sgp_address_dst, unsigned int sgp_address_src, unsigned int width, unsigned int height ) {
   
    CHECK_INIT();

    unsigned int i,j,k;
    unsigned int l,m,n;
 
    SGPSendPacket( MEMCPY | TWO_D | SGP_MEMORY_TO_SGP_MEMORY | NUMPACKETS(3) ,0, config );
    SGPSendPacket( sgp_address_dst ,0, config );
    SGPSendPacket( sgp_address_src ,0, config );
    SGPSendPacket( DIM_X(width) | DIM_Y(height) ,0, config );

    GLV.glMatrixMode(GL_MODELVIEW);
    GLV.glPushMatrix();
    GLV.glLoadIdentity();

    for(i=sgp_address_src,j=sgp_address_dst,k=0; k<height; i+=2048,j+=2048,k++) {
	GLV.glRasterPos2d(j%2048, j/2048);
        for(l=i, m=j, n=0; n<width; l++, m++, n++) {
            simMemory[m] = simMemory[l];
        }
	GLV.glDrawPixels(width,1,GL_BGRA, GL_UNSIGNED_BYTE, &simMemory[j]);
    }

    GLV.glPopMatrix();

}

void drawSprite( unsigned int sgp_address_dst, unsigned int sgp_address_src, unsigned int width, unsigned int height ) {

   CHECK_INIT();

   unsigned int i,j,k;
   unsigned int l,m,n;

   SGPSendPacket( MEMCPY | TWO_D | DROP_ALPHA | SGP_MEMORY_TO_SGP_MEMORY | NUMPACKETS(3) ,0, config );
   SGPSendPacket( sgp_address_dst ,0, config );
   SGPSendPacket( sgp_address_src ,0, config );
   SGPSendPacket( DIM_X(width) | DIM_Y(height) ,0, config );

   GLV.glMatrixMode(GL_MODELVIEW);
   GLV.glPushMatrix();
   GLV.glLoadIdentity();
   GLV.glMatrixMode(GL_PROJECTION);
   GLV.glLoadIdentity();
   GLV.glOrtho(0, 1279, 1023, 0, -1, 1);

   for(i=sgp_address_src,j=sgp_address_dst,k=0; k<height; i+=2048,j+=2048,k++) {
       GLV.glRasterPos2d(j%2048,j/2048);
       for(l=i, m=j, n=0; n<width; l++, m++, n++) {
           if( (simMemory[l] & 0xff000000) != 0) {
               simMemory[m] = simMemory[l];
           }
       }
       GLV.glDrawPixels(width,1, GL_BGRA, GL_UNSIGNED_BYTE, &simMemory[j]);
   }
   GLV.glPopMatrix();
   GLV.glMatrixMode(GL_MODELVIEW);
   GLV.glPopMatrix();

}

