/* -----------------------------------------------------------------------
 * Mike Steffen    (steffma@iastate.edu)  
 * Joseph Zambreno (zambreno@iastate.edu)
 * Iowa State University
*/

#include "sgp_driver_utils.h"

// Conv functions
vertex_t vertex_conv(fixpt64 x, fixpt64 y, fixpt64 z, fixpt64 w) {
        vertex_t r;
        r.x = x;
        r.y = y;
        r.z = z;
	r.w = w;
        return r;
} 

color_t color_conv(unsigned int r, unsigned int g, unsigned int b, unsigned int a) {
   color_t x;
   x = (a & 0xff000000) | ((r >> 8) & 0x00ff0000) | ((g >> 16) & 0x0000ff00) | (b >> 24);
   return x;
}

#define VERTEXCONVERT(typeDef, dataType) fixpt64 inline conv32hf_##typeDef ( dataType value) {       \
                                            typedef union{ int s; unsigned int u;} FIXI;                    \
                                            FIXI I; I.s = (int) value;                                      \
                                            fixpt64 r; r.frac = 0; r.whole = I.u ;                           \
                                            return r;                                                       \
                                         }

VERTEXCONVERT(i,GLint)
VERTEXCONVERT(s,GLshort)

unsigned int inline conv32h_ub(GLubyte value) {
        return ((unsigned int) value);
}
unsigned int inline conv32h_us(GLushort value) {
        return ((unsigned int) value);
}
unsigned int inline conv32h_ui(GLuint value) {
        return ((unsigned int) value);
}
unsigned int inline conv32h_b(GLbyte value) {
        typedef union {
                int s;
                unsigned int u;
        } FIXI;
        FIXI I;  I.s = (int)value;
        return I.u;
}
unsigned int inline conv32h_s(GLshort value) {
        typedef union {
                int s;
                unsigned int u;
        } FIXI;
        FIXI I;  I.s = (int)value;
        return I.u;
}
unsigned int inline conv32h_i(GLint value) {
        typedef union {
                int s;
                unsigned int u;
        } FIXI;
        FIXI I;  I.s = (int)value;
        return I.u;
}

fixpt64 inline conv32hf_d(GLdouble value) {

     typedef union {
         int s;                  // signed data type
         unsigned int u;         // unsigned data type
     } FIXI;

     FIXI I;
     fixpt64 returnValue;

     if((value < 3E-10) && (value > -3E-10)) {
	   returnValue.whole=0;
	   returnValue.frac=0;
           return returnValue;
     }



     I.s = ( (int)value + ((value - (int)value < 0) ? -1:0) );           // compute whole part of the number
     returnValue.whole = I.u;

     float PosA = (value >= 0.0) ? value:-value ;                        // remove sign (+ or -) for fractional number

     // Compute fractional number
     unsigned int F = (  (unsigned int)((   PosA - (int)PosA + ((PosA < (int)PosA) ? 1:0)) * 4294967296LL)       );
     returnValue.frac = F;

     if(value < 0) {
        returnValue.frac = ~returnValue.frac+1;
     }


     return returnValue;

}

fixpt64 inline conv32hf_f(GLfloat value) {

     typedef union {
         int s;                  // signed data type
         unsigned int u;         // unsigned data type
     } FIXI;

     FIXI I;
     fixpt64 returnValue;

     if((value < 3E-10) && (value > -3E-10)) {
           returnValue.whole=0;
           returnValue.frac=0;
           return returnValue;
     }

     I.s = ( (int)value + ((value - (int)value < 0) ? -1:0) );           // compute whole part of the number
     returnValue.whole = I.u;

     float PosA = (value >= 0.0) ? value:-value ;                        // remove sign (+ or -) for fractional number

     // Compute fractional number
     unsigned int F = (  (unsigned int)((   PosA - (int)PosA + ((PosA < (int)PosA) ? 1:0)) * 4294967296LL)       );
     returnValue.frac = F;

     // if we have negative number 2s complement
     if(value < 0) {
	returnValue.frac = ~returnValue.frac+1;	
     }
     return returnValue;

}


// convert double to fractal value
unsigned int inline conv32f_d(GLdouble value) {
     typedef union {
         int s;                  // signed data type
         unsigned int u;         // unsigned data type
     } FIXI;

     FIXI I;

     if((value < 3E-10) && (value > -3E-10)) {
           return 0;
     }


     I.s = ( (int)value + ((value - (int)value < 0) ? -1:0) );           // compute whole part of the number

     float PosA = (value >= 0.0) ? value:-value ;                        // remove sign (+ or -) for fractional number

     // Compute fractional number
     unsigned int F = (  (unsigned int)((   PosA - (int)PosA + ((PosA < (int)PosA) ? 1:0)) * 4294967296LL)       );

     if(value < 0) {
        F = ~F+1;
     }



     // Format whole and fractional number to 2.30 format
     return  ( ( ( I.u << 30 ) & 0xc0000000) | (0x3fffffff & (unsigned int)(F >> 2)));

}

// convert doulbe to color value
unsigned int inline conv32c_d(GLdouble value) {

     if(value >= 1.0) {
        return ~0x00;
     }

     if(value < 0.0) {
        return 0x00;
     }

     float PosA = (value >= 0.0) ? value:-value ;                        // remove sign (+ or -) for fractional number

     // Compute fractional number
     unsigned int F = (  (unsigned int)((   PosA - (int)PosA + ((PosA < (int)PosA) ? 1:0)) * 4294967296LL)       );


     if(value < 0) {
        F = ~F+1;
     }


     // Format whole and fractional number to 2.30 format
     return  F;


}

// convert float to fractal values
unsigned int inline conv32f_f(GLfloat value) {
     typedef union {
         int s;                  // signed data type
         unsigned int u;         // unsigned data type
     } FIXI;

     FIXI I;

     if((value < 3E-10) && (value > -3E-10)) {
           return 0;
     }


     I.s = ( (int)value + ((value - (int)value < 0) ? -1:0) );           // compute whole part of the number

     float PosA = (value >= 0.0) ? value:-value ;                        // remove sign (+ or -) for fractional number

     // Compute fractional number
     unsigned int F = (  (unsigned int)((   PosA - (int)PosA + ((PosA < (int)PosA) ? 1:0)) * 4294967296LL)       );
 
      if(value < 0) {
        F = ~F+1;
     }



     // Format whole and fractional number to 2.30 format
     return (  ( ( I.u << 30 ) & 0xc0000000) | (0x3fffffff & (unsigned int)(F >> 2)));

}

// Convert float to color channel
unsigned int inline conv32c_f(GLfloat value) {

     if(value >= 1.0f) {
        return ~0x00;
     }

     if(value < 0.0f) {
        return 0x00;
     }

     float PosA = (value >= 0.0) ? value:-value ;                        // remove sign (+ or -) for fractional number

     // Compute fractional number
     unsigned int F = (  (unsigned int)((   PosA - (int)PosA + ((PosA < (int)PosA) ? 1:0)) * 4294967296LL)       );

      if(value < 0) {
        F = ~F+1;
     }


     // return number as fractoinal 32 bit format
     return F;

}

unsigned int inline conv32h_d(GLdouble value) {
     typedef union {
         int s;                  // signed data type
         unsigned int u;         // unsigned data type
     } FIXI;

     FIXI I;

     if((value < 3E-10) && (value > -3E-10)) {
           return 0;
     }


     I.s = ( (int)value + ((value - (int)value < 0) ? -1:0) );           // compute whole part of the number
     return I.u;

}

unsigned int inline conv32h_f(GLfloat value) {
     typedef union {
         int s;                  // signed data type
         unsigned int u;         // unsigned data type
     } FIXI;

     FIXI I;

     if((value < 3E-10) && (value > -3E-10)) {
           return 0;
     }


     I.s = ( (int)value + ((value - (int)value < 0) ? -1:0) );           // compute whole part of the number

     return I.u;
}

unsigned int inline conv8D24_d(GLdouble value) {

     typedef union {
	int s;
	unsigned int u;
     } FIXI;

     FIXI I;
     unsigned int returnValue;

     if((value < 3E-10) && (value > -3E-10)) {
	returnValue = 0x00000000;
	return returnValue;
     }

     I.s = ( (int)value + ((value - (int)value < 0) ? -1:0) );           // compute whole part of the number
     returnValue = I.u << 24;

     float PosA = (value >= 0.0) ? value:-value ;                        // remove sign (+ or -) for fractional number
      
      // Compute fractional number
     unsigned int F = (  (unsigned int)((   PosA - (int)PosA + ((PosA < (int)PosA) ? 1:0)) * 4294967296LL)       );

     if(value < 0) {
          F = ~F + 1;
     }

     returnValue = returnValue | (F >> 8);
     

     printf("Untested code: input: %lf => 0x%x.  Is this right?\n", value, returnValue);
     return returnValue;

}

unsigned int inline conv8D24_f(GLfloat value) {

     typedef union {
        int s;
        unsigned int u;
     } FIXI;

     FIXI I;
     unsigned int returnValue;

     if((value < 3E-10) && (value > -3E-10)) {
        returnValue = 0x00000000;
        return returnValue;
     }

     I.s = ( (int)value + ((value - (int)value < 0) ? -1:0) );           // compute whole part of the number
     returnValue = I.u << 24;


     float PosA = (value >= 0.0) ? value:-value ;                        // remove sign (+ or -) for fractional number

      // Compute fractional number
     unsigned int F = (  (unsigned int)((   PosA - (int)PosA + ((PosA < (int)PosA) ? 1:0)) * 4294967296LL)       );

     if(value < 0) {
          F = ~F + 1;
     }

     returnValue = returnValue | (F >> 8);
     return returnValue;
}

