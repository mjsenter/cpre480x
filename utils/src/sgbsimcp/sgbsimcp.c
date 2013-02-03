/*****************************************************************************
 * Joseph Zambreno               
 * Michael Steffen
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgbsimcp.c - sgbsimcp application - takes as input a binary trace file
 * of SGP commands and copies them to the hw/sim/ directory, after stripping
 * any memOps commands (which can take a very long time to simulate). 
 *
 *
 * NOTES:
 * 3/1/11 by JAZ::Design created.
 *****************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sgp_driver_utils.h>
#include <sgp.h>

extern size_t strlen(const char *s);

int main(int argc, char **argv) {

  unsigned int packet, length, opcode, addr;
  int stripMode = 1, memcnt;
  int i, j;
  FILE *inFile;
  char *outName1, *outName2;
  char outName_suffix[] = "/hw/sim/trace.sgb";

  FILE *outFile;

  if(argc < 2) {
    printf("Usage: %s [-n] <file>\n", argv[0]);
    return -1;
  }

  for (i = 1; i < argc-1; i++) {
    if (argv[i][0] != '-' || strlen(argv[i]) != 2) {
      printf("Usage: %s [-n] <file>\n", argv[0]);
      return -1;
    }
    if (argv[i][1] == 'n') {
      stripMode = 0;
    }
  }

  inFile = fopen(argv[argc-1],"rb");
  if(inFile == NULL) {
    printf("Cannot open input tracefile %s\n", argv[argc-1]);
    return -2;
  }

  // Grab the current directory from the setup.sh environmental setup
  // and append the trace.sgb hard-coded directory name
  outName1 = getenv("CDIR");
  outName2 = malloc(strlen(outName1)+18);
  strcpy(outName2, outName1);
  strcat(outName2, outName_suffix);
  outFile = fopen(outName2, "wb");

  if (outFile == NULL) {
    printf("Cannot open output tracefile %s for writing\n", outName2);
    return -2;
  }

  printf("\nCopying tracefile %s to %s\n", argv[argc-1], outName2);

 
  // If we're not stripping, just perform a copy. There are more efficient
  // ways to do this of course. 
  if (!stripMode) {

    while(!feof(inFile)) {
      
      fread(&packet, 1, sizeof(unsigned int), inFile);
      fwrite(&packet, 1, sizeof(unsigned int), outFile);
    }

  }

  else {

    memcnt = 0;
    while(!feof(inFile)) {
      fread(&packet, 1, sizeof(unsigned int), inFile);
      
      // Assume first packet has length information
      length = (packet & 0xFFFFF000) >> 12;
      opcode = (packet & 0x00000FF0) >> 4;
      addr =   (packet & 0x0000000F);

      // Strip out any instructions that address the memOps module
      if (addr == (MEMCPY & 0xF)) {

	memcnt++;
	for (j = 0; j < length; j++) {

	  if (feof(inFile)) {
	    printf("ERROR: Early termination of traceFile %s\n", argv[argc-1]);
	    exit(-1);
	  }

	  fread(&packet, 1, sizeof(unsigned int), inFile);
	}
      }

      // Otherwise, write the packets corresponding to those instructions
      else {

	fwrite(&packet, 1, sizeof(unsigned int), outFile);	

	for (j = 0; j < length; j++) {

	  if (feof(inFile)) {
	    printf("ERROR: Early termination of traceFile %s\n", argv[argc-1]);
	    exit(-1);
	  }

	  fread(&packet, 1, sizeof(unsigned int), inFile);
	  fwrite(&packet, 1, sizeof(unsigned int), outFile);	
	}
      }

    }

    printf("\nStripped %d memOps instruction", memcnt);
    if (memcnt != 1) printf("s");
    printf("\n");

  }

  fclose(inFile);
  fclose(outFile);

  return 0;

}
