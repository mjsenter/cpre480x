/* -----------------------------------------------------------------------
 * Mike Steffen    (steffma@iastate.edu)  
 * Joseph Zambreno (zambreno@iastate.edu)
 * Iowa State University
 * slideshow.cpp - loads a set of .bmp file and transmits them peridocally
 * as GL_POINTS
*/

#include <stdio.h>

#include <GL/glut.h>
#include <GL/gl.h>
#include <simpleGLU.h>

unsigned char *gdata[256];
unsigned short gwidth[256], gheight[256];
int num_images;

void glInit()
{
    glClearColor(1.0f, 1.0f, 1.0f, 0.0f);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, 1279, 1023, 0, -1, 1);

    glMatrixMode(GL_MODELVIEW);
   glLoadIdentity();
}

void myTimerFunc(int input) {
  short height, width;
  unsigned char *data;

  static int cur = 0;

  height = gheight[cur];
  width = gwidth[cur];
  data = gdata[cur];

  glClear(GL_COLOR_BUFFER_BIT);
  glPointSize(1.0);

  glBegin(GL_POINTS);
  for(unsigned int y=0; y < height; y++) {
    for(unsigned int x = 0; x < width; x++) {
      glColor3ub(data[ y*width*4 + x*4 + 1 ],data[y*width*4 + x*4 + 2],data[ y*width*4 + x*4 + 3]);
      glVertex2i(x,y);
    }
  }
  glEnd();
  glFlush();

  cur++;
  cur = cur % num_images;

  glutTimerFunc(1000, myTimerFunc, 0);
}

void loadImage(char* filename) {
	
    
  int error = sgluLoadBitmap(filename, &gwidth[num_images], &gheight[num_images], &gdata[num_images]);
  if(error < 0) {
    printf("Error opening file %s\n - error: %d", filename, error);
    exit(0);
  }
  num_images++;
}

int main(int argc, char** argv) {

  int i;
  num_images = 0;
  if(argc < 2) {
    printf("Error: Bad arguments\n  Usage: %s File1.bmp <File2.bmp> <File3.bmp>\n", argv[0]);
    exit(0);
  }

  glutInit(&argc, argv);
  glutInitDisplayMode(GLUT_SINGLE | GLUT_RGB);
  glutInitWindowSize(1280, 1024);
  glutCreateWindow("SGL point test");
  glutTimerFunc(1000, myTimerFunc, 0);
  glInit();

  for (i = 1; i < argc; i++) {
    loadImage(argv[i]);
  }
  glutMainLoop();

  return 0;
}
