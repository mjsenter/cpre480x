#ifndef __SGP_H_
#define __SGP_H_

#include <termios.h>
#include <fcntl.h>
#include <sys/types.h> 
#include <netinet/in.h> 
#include <netdb.h> 
#include <sys/socket.h> 



// OpCode Defines ---------------------------
#define NOOP		0x00


// microArch Addresses
#define PIPEFRONT 	0x03
#define PIXELOPS	0x02
#define MEMCPY		0x11
#define MEMSET		0x41

// Pipe Front opCodes
#define INDEX_QUEUE		0x000
#define COLOR_QUEUE		0x010
#define VERTEX_X_HOLE_QUEUE	0x020
#define VERTEX_X_FRAC_QUEUE	0x030
#define VERTEX_Y_HOLE_QUEUE	0x040
#define VERTEX_Y_FRAC_QUEUE	0x050
#define VERTEX_Z_HOLE_QUEUE	0x060
#define VERTEX_Z_FRAC_QUEUE	0x070
#define FLUSH_QUEUE		0x800

// MEMCPY opCodes
#define LINEAR			 0x020
#define TWO_D			 0x000
#define HOST_TO_SGP_MEMORY	 0x040
#define SGP_MEMORY_TO_SGP_MEMORY 0x0C0
#define DROP_ALPHA		 0x100
#define SGP_MEMORY_TO_SGP( x )	 ( (((x) & 0x70) << 5) |  0x80 )

// MemCpy Functions
#define DIM_X( x ) ( (x) & 0xFFFF )
#define DIM_Y( y ) ( ( (y) & 0xFFFF) << 16 )

// Num Packets
#define NUMPACKETS(x)  (( (x) & 0x7ffff) << 12)

#endif
