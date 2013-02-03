#ifndef __SIMPLE_2D_H__
#define __SIMPLE_2D_H__

/* check if the compiler is of C++ */
#ifdef __cplusplus
extern "C" {
#endif

     void createSprite( unsigned int sgp_address, unsigned char *dataSource, unsigned int width, unsigned int height );
     void SGPMemSet( unsigned int sgp_address, unsigned int value, unsigned int width, unsigned int height );
     void SGPMemCpy( unsigned int sgp_address_dst, unsigned int sgp_address_src, unsigned int width, unsigned int height );
     void drawSprite( unsigned int sgp_address_dst, unsigned int sgp_address_src, unsigned int width, unsigned int height );

#ifdef __cplusplus
}
#endif

#endif
