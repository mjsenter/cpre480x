/*****************************************************************************
 * Joseph Zambreno               
 * Michael Steffen
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgbhexdump.c - sgbhexdump application - takes as input a binary trace file
 * of SGP commands and prints them out as hex or as decoded binary. 
 * Ed's favorite utility. 
 *
 *
 * NOTES:
 * 2/8/11 by JAZ::Design created.
 *****************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <sgp_driver_utils.h>
#include <sgp.h>

extern size_t strlen(const char *s);

int main(int argc, char **argv) {

  unsigned int packet, length, opcode, addr;
  int disassembleMode = 0;
  int i, j;
  FILE *traceFile;

  if(argc < 2) {
    printf("Usage: %s [-d] <file>\n", argv[0]);
    return -1;
  }

  for (i = 1; i < argc-1; i++) {
    if (argv[i][0] != '-' || strlen(argv[i]) != 2) {
      printf("Usage: %s [-d] <file>\n", argv[0]);
      return -1;
    }
    if (argv[i][1] == 'd') {
      disassembleMode = 1;
    }
  }

  traceFile = fopen(argv[argc-1],"rb");
  if(traceFile == NULL) {
    printf("Cannot open file %s\n", argv[argc-1]);
    return -2;
  }


  if (!disassembleMode) {

    i = 0;
    while(!feof(traceFile)) {

      fread(&packet, 1, sizeof(unsigned int), traceFile);
      printf(" Packet %5d: %08x\n", i++, packet);  
    }

  }

  else {

    i = 0;
    while(!feof(traceFile)) {

      fread(&packet, 1, sizeof(unsigned int), traceFile);
      
      // Assume first packet has length information
      length = (packet & 0xFFFFF000) >> 12;
      opcode = (packet & 0x00000FF0) >> 4;
      addr =   (packet & 0x0000000F);

      printf("\nPacket %05d: %08x (Instruction Packet)\n", i++, packet);
      printf("| X | LENGTH | OPCODE | ADDR |\n");
      printf("| 0 |  %05x |     %02x |    %01x |\n\n", length, opcode, addr);
      
      for (j = 0; j < length; j++) {

	if (feof(traceFile)) {
	  printf("ERROR: Early termination of traceFile %s\n", argv[argc-1]);
	  exit(-1);
	}

	fread(&packet, 1, sizeof(unsigned int), traceFile);
	printf("Packet %05d: %08x\n", i++, packet);  
      }	
    }

  }

  fclose(traceFile);

  return 0;

}
