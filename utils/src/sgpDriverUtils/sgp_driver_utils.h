/* -----------------------------------------------------------------------
 * Mike Steffen    (steffma@iastate.edu)  
 * Joseph Zambreno (zambreno@iastate.edu)
 * Iowa State University
*/

#ifndef _SGP_DRIVER_UTILS_H__
#define _SGP_DRIVER_UTILS_H__

// Additoinal includes ----------------------------------------
#include <GL/gl.h>
#include <stdio.h>
#include <netinet/in.h>

// Defines ----------------------------------------------------
// Ethernet config
#define MYPORT 0xAE23
#define MAXBUFLEN 1024

// SGP Driver Modes
#define SGP_UART   0x00000001
#define SGP_ETH    0x00000002
#define SGP_FILE   0x00000004
#define SGP_STDOUT 0x00000008
#define SGP_VBIOS  0x00000010


// Data structures --------------------------------------------
// Structure to hold configuration information
typedef struct {
  char *sgp_transmit;
  char *sgp_trace;
  char *sgp_port;
  char *sgp_name;
  int rs232;
  unsigned int driverMode;
  FILE *traceFile;
  FILE *biosFile;
  int sockfd;
  struct sockaddr_in my_addr;
  struct sockaddr_in their_addr;
  struct sockaddr_in rv_addr;
  struct hostent *he;
  char buf[MAXBUFLEN];
} sgp_config;

/* 64-bit fix point struct */
typedef struct
{
    unsigned whole;
    unsigned frac;
} fixpt64;

typedef unsigned int color_t;

typedef struct
{
   fixpt64 x,y,z,w;
} vertex_t;


// Function -------------------------------------------------
int configSGPTransmit(sgp_config **config_in, char enableLog);
void endSGPTransmit(sgp_config *config);
void SGPSendPacket(unsigned int packet, char flush, sgp_config *config);

// Converstion Functions
vertex_t vertex_conv(fixpt64 x, fixpt64 y, fixpt64 z, fixpt64 w);
color_t color_conv(unsigned int r, unsigned int g, unsigned int b, unsigned int a);

fixpt64 inline conv32hf_i(GLint value);
fixpt64 inline conv32hf_s(GLshort value);
unsigned int inline conv32h_ub(GLubyte value);
unsigned int inline conv32h_us(GLushort value);
unsigned int inline conv32h_ui(GLuint value);
unsigned int inline conv32h_b(GLbyte value);
unsigned int inline conv32h_s(GLshort value);
unsigned int inline conv32h_i(GLint value);
fixpt64 inline conv32hf_d(GLdouble value);
fixpt64 inline conv32hf_f(GLfloat value);
unsigned int inline conv32f_d(GLdouble value);
unsigned int inline conv32c_d(GLdouble value);
unsigned int inline conv32f_f(GLfloat value);
unsigned int inline conv32c_f(GLfloat value);
unsigned int inline conv32h_d(GLdouble value);
unsigned int inline conv32h_f(GLfloat value);
unsigned int inline conv8D24_d(GLdouble value);
unsigned int inline conv8D24_f(GLfloat value);

#endif
