/* -----------------------------------------------------------------------
 * Mike Steffen    (steffma@iastate.edu)  
 * Joseph Zambreno (zambreno@iastate.edu)
 * Iowa State University
*/

#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <fcntl.h>
#include <netdb.h>
#include <sys/socket.h>
#include <sgp.h>
#include "sgp_driver_utils.h"

int configSGPTransmit(sgp_config **config_in, char enableLog) {

  sgp_config *config;

  *config_in = (sgp_config *)malloc(1*sizeof(sgp_config));
  config = *config_in;

  config->sgp_transmit = getenv("SGP_TRANSMIT");
  config->sgp_trace = getenv("SGP_TRACE");
  config->sgp_port = getenv("SGP_PORT");
  config->sgp_name = getenv("SGP_NAME");

  config->rs232 = 0;
  config->driverMode = 0;
  config->traceFile = NULL;
  config->biosFile = NULL;

  if(enableLog == 0) {
    config->sgp_trace = NULL;
  }

  struct termios options;

  // If SGP_TRANSMIT is set to UART, open up a UART port
  if (config->sgp_transmit != NULL) {
        if (strcmp(config->sgp_transmit, "UART") == 0) {
          if (config->sgp_port == NULL) {
                config->rs232 = open("/dev/ttyS0", O_RDWR | O_NOCTTY | O_NDELAY );
          }
          else {
                config->rs232 = open(config->sgp_port,  O_RDWR | O_NOCTTY | O_NDELAY );
          }
          config->driverMode |= SGP_UART;
        }

        // If SGP_TRANSMIT is set to ETH, open up an ethernet port
        if (strcmp(config->sgp_transmit, "ETH") == 0) {
          if (config->sgp_port == NULL) {
                config->he = gethostbyname("192.168.1.12");
          }
          else {
                config->he = gethostbyname(config->sgp_port);
          }

          config->driverMode |= SGP_ETH;
        }
  }

  // If SGP_TRACE is set to FILE, open up a binary trace file
  if (config->sgp_trace != NULL) {
        if (strcmp(config->sgp_trace, "FILE") == 0) {
          if (config->sgp_name == NULL) {
                config->traceFile = fopen("trace.sgb", "wb");
          }
          else {
                config->traceFile = fopen(config->sgp_name, "wb");
          }
          config->driverMode |= SGP_FILE;
        }

        // If SGP_TRACE is set to VBIOS, open up a hex trace file
        if (strcmp(config->sgp_trace, "VBIOS") == 0) {
          if (config->sgp_name == NULL) {
                config->biosFile = fopen("trace.dat", "w");
          }
          else {
                config->biosFile = fopen(config->sgp_name, "w");
          }
          fprintf (config->biosFile, "memory_initialization_radix=16;\nmemory_initialization_vector=\n");
          config->driverMode |= SGP_VBIOS;
        }

        if (strcmp(config->sgp_trace, "STDOUT") == 0) {
          config->driverMode |= SGP_STDOUT;
        }
  }

  if (config->driverMode & SGP_UART) {
        if(config->rs232 == -1) {
          return -1;
        }

        fcntl(config->rs232,F_SETFL, 0);
        // get current serial port configuration
    if(tcgetattr(config->rs232, &options) != 0) {
      return -3;
    }

    // Set input baud rate to 115200
    if(cfsetispeed(&options, B115200) != 0) {
      return -4;
    }


    // Set output baud rate to 115200
    if(cfsetospeed(&options, B115200) != 0) {
      return -5;
    }

    options.c_cflag |= (CLOCAL | CREAD);

    // Config No parity 8 bit data
    options.c_cflag &= ~PARENB;
    options.c_cflag &= ~CSTOPB;
    options.c_cflag &= ~CSIZE;
    options.c_cflag |= CS8;

    options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG); // set up raw input
    //options.c_iflag |= (IXON | IXOFF | IXANY);                
         options.c_iflag |= IXON;                                       // enable software control flow         
    options.c_oflag &= ~OPOST;                          // enable raw output

    options.c_cc[VSTART] = 0x11;                                // start bit for software flow control (XON)
    options.c_cc[VSTOP] = 0x13;                         // stop bit for software flow control (XOFF)

    // set serial configs.
    if(tcsetattr(config->rs232, TCSANOW, &options) != 0) {
      return -6;
    }
  }


  if (config->driverMode & SGP_ETH) {
        if (config->he == NULL) {
          herror("gethostbyname");
          return -7;
        }

        config->sockfd = socket(AF_INET, SOCK_DGRAM, 0);
        if (config->sockfd == -1) {
          perror("socket");
          return -8;
        }

        // Set up socket information of Packet destination
        config->their_addr.sin_family = AF_INET;
        config->their_addr.sin_port = htons(MYPORT);
        config->their_addr.sin_addr = *((struct in_addr *)config->he->h_addr);
        //bzero(&(config->their_addr.sin_zero), 8); // replace with memset
	memset(&(config->their_addr.sin_zero), '\0', 8);

        // Set up socket information of Packet source
        config->my_addr.sin_family = AF_INET;
        config->my_addr.sin_port = htons(MYPORT);
        config->my_addr.sin_addr.s_addr = INADDR_ANY;
        //bzero(&(config->my_addr.sin_zero), 8); // replace with memset
	memset(&(config->my_addr.sin_zero), '\0', 8);


        // Bind port MYPORT to this program 
        // Lets OS know to route MYPORT packets to me
        if(bind(config->sockfd,(struct sockaddr *)&config->my_addr,
                        sizeof(struct sockaddr))== -1) {
          //  perror("bind");
          //return -9;
        }

  }
  return 0;
}

void endSGPTransmit(sgp_config *config) {

    if (config->driverMode & SGP_UART) {
        close(config->rs232);
    }

    if (config->driverMode & SGP_ETH) {
      close(config->sockfd);
    }

    if (config->driverMode & SGP_FILE) {
      fclose(config->traceFile);
    }

    if (config->driverMode & SGP_VBIOS) {
      fprintf (config->biosFile, "00000002;");
      fclose(config->biosFile);
    }
}


void SGPSendPacket(unsigned int packet, char flush, sgp_config *config) {
  unsigned char sendPacket;
  static int buflen = 0;
  int tot_sent, cur_sent;


  // For a UART packet, we might as well send it right away
  if (config->driverMode & SGP_UART) {
        sendPacket = (packet >> 24) & 0xff;
        write(config->rs232, &sendPacket, sizeof(char));
        sendPacket = (packet >> 16) & 0xff;
        write(config->rs232, &sendPacket, sizeof(char));
        sendPacket = (packet >> 8) & 0xff;
        write(config->rs232, &sendPacket, sizeof(char));
        sendPacket = packet & 0xff;
        write(config->rs232, &sendPacket, sizeof(char));
  }

  // For ETH communication, create packets of MAXBUFLEN, unless there is 
  // an ACK request. 
  if (config->driverMode & SGP_ETH) {

        config->buf[buflen] = (packet >> 24) & 0xff;
        config->buf[buflen+1] = (packet >> 16) & 0xff;
        config->buf[buflen+2] = (packet >> 8) & 0xff;
        config->buf[buflen+3] = packet & 0xff;
        buflen += 4;

        if ((buflen == MAXBUFLEN) || flush) { 
          tot_sent = 0;
          while (buflen > 0) {
                cur_sent = sendto(config->sockfd, config->buf+tot_sent,
                                                   buflen, 0,
                                                   (struct sockaddr *)&config->their_addr,
                                                   sizeof(struct sockaddr));
		if (cur_sent == -1) {
                  perror("sendto"); fflush(stdout);
                }
                tot_sent += cur_sent;
                buflen -= cur_sent;
          }
        }
  }

  if(config->driverMode & SGP_FILE) {
        fwrite(&packet, sizeof(unsigned int), 1, config->traceFile);
  }

  if(config->driverMode & SGP_STDOUT) {
        printf("0x%x\n", packet);
  }

  if(config->driverMode & SGP_VBIOS) {
          fprintf (config->biosFile, "%08x,\n",packet);
  }
}

