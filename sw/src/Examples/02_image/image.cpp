/* -----------------------------------------------------------------------
 * Mike Steffen    (steffma@iastate.edu)  
 * Joseph Zambreno (zambreno@iastate.edu)
 * Iowa State University
 * image.cpp - loads a .bmp file and transmits as GL_POINTS
*/

#include <stdio.h>

#include <GL/glut.h>
#include <GL/gl.h>
#include <simpleGLU.h>

unsigned char *data;
unsigned short width, height;

void glInit()
{
    glClearColor(0.0f, 0.0f, 1.0f, 0.0f);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, 1279, 1023, 0, -1, 1);

    glMatrixMode(GL_MODELVIEW);
   glLoadIdentity();
}

void myDisplay()
{
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
}

void loadImage(char* filename) {
	
    
    int error = sgluLoadBitmap(filename, &width, & height, &data);
    if(error <= 0) {
      printf("Error opening file %s - error %d\n", filename, error);
	exit(0);
    }
}

int main(int argc, char** argv)
{

   if(argc != 2) {
	printf("Error: Bad arguments\n  Usage: %s imageFile.bmp\n", argv[0]);
	exit(0);
   }

   glutInit(&argc, argv);
   glutInitDisplayMode(GLUT_SINGLE | GLUT_RGB);
   glutInitWindowSize(1280, 1024);
   glutCreateWindow("SGL point test");
   glutDisplayFunc(myDisplay);
   glInit();

   loadImage(argv[1]);
   glutMainLoop();

   return 0;
}
