/*****************************************************************************
 * Joseph Zambreno               
 * Michael Steffen
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgbreplay.c - sgbreplay application - takes as input a binary trace file
 * of SGP commands and sends them over the specified port. 
 *
 *
 * NOTES:
 * 1/1/11 by JAZ::Design created.
 *****************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <fcntl.h>
#include <sys/types.h> 
#include <netinet/in.h> 
#include <netdb.h> 
#include <sys/socket.h> 
#include <sgp_driver_utils.h>
#include <sgp.h>

int main(int argc, char **argv) {

  sgp_config *config;
  unsigned char replayMode = 0;
  unsigned int packet;
  int i;
  FILE *traceFile;
  unsigned int jmpCnt = 0;

  if(argc < 2) {
    printf("Usage: %s [-i][-j number] <file>\n", argv[0]);
    return -1;
  }

  for (i = 1; i < argc-1; i++) {
    if (argv[i][0] != '-' || strlen(argv[i]) != 2) {
      printf("Usage: %s [-i][-j number]  <file>\n", argv[0]);
      return -1;
    }
    if (argv[i][1] == 'i') {
      replayMode = 1;
    }
    if (argv[i][1] == 'j') {
      replayMode=1;
      jmpCnt=atoi(argv[i+1]);
      i++;
    }

  }

  traceFile = fopen(argv[argc-1],"rb");
  if(traceFile == NULL) {
    printf("Cannot open file %s\n", argv[argc-1]);
    return -2;
  }


  configSGPTransmit(&config, 0);

  if (replayMode == 1) {

    i = 0;
    while(!feof(traceFile)) {

      fread(&packet, 1, sizeof(unsigned int), traceFile);

      printf(" Packet %d |---> %08x", i++, packet);
      if(i > jmpCnt) {
         getchar();
      }
      SGPSendPacket(packet, 1, config);
      printf("  |   |-----> Sent\n");
    
    }
  }

  else {
	
    while (!feof(traceFile)) {

      // Note: buf is probably big-endian. Need to switch it out
      fread(&packet, 1, sizeof(unsigned int), traceFile);
      SGPSendPacket(packet, 0, config);

    }
	   
  }
  SGPSendPacket(0x00, 1, config);

  fclose(traceFile);
  endSGPTransmit(config);

  return 0;

}
