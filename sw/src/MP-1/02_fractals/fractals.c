/* -----------------------------------------------------------------------
 * Mike Steffen    (steffma@iastate.edu)  
 * Joseph Zambreno (zambreno@iastate.edu)
 * Iowa State University
 * fractals.c - Calculates a fractal image using a simple colormap
*/

#include <stdio.h>
#include <math.h>
#include <GL/glut.h>


void glInit() {
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, 1280, 1024, 0, -1, 1);
}

void myDisplay() {

  int width = 1280;
  int height = 1024;
  double xaxis[2] = {-2.0, 0.7};
  double yaxis[2] = {-1.0, 1.0};
 
  // Matlab default colormap. Feel free to modify
  double cmap[64][3] = {{0.0000, 0.0000, 0.5625}, 
			{0.0000, 0.0000, 0.6250},
			{0.0000, 0.0000, 0.6875},
			{0.0000, 0.0000, 0.7500},
			{0.0000, 0.0000, 0.8125},
			{0.0000, 0.0000, 0.8750},
			{0.0000, 0.0000, 0.9375},
			{0.0000, 0.0000, 1.0000},
			{0.0000, 0.0625, 1.0000},
			{0.0000, 0.1250, 1.0000},
			{0.0000, 0.1875, 1.0000},
			{0.0000, 0.2500, 1.0000},
			{0.0000, 0.3125, 1.0000},
			{0.0000, 0.3750, 1.0000},
			{0.0000, 0.4375, 1.0000},
			{0.0000, 0.5000, 1.0000},
			{0.0000, 0.5625, 1.0000},
			{0.0000, 0.6250, 1.0000},
			{0.0000, 0.6875, 1.0000},
			{0.0000, 0.7500, 1.0000},
			{0.0000, 0.8125, 1.0000},	
			{0.0000, 0.8750, 1.0000},		
			{0.0000, 0.9375, 1.0000},
			{0.0000, 1.0000, 1.0000},
			{0.0625, 1.0000, 0.9375},
			{0.1250, 1.0000, 0.8750},
			{0.1875, 1.0000, 0.8125},
			{0.2500, 1.0000, 0.7500},
			{0.3125, 1.0000, 0.6875},
			{0.3750, 1.0000, 0.6250},
			{0.4375, 1.0000, 0.5625},
			{0.5000, 1.0000, 0.5000},
			{0.5625, 1.0000, 0.4375},
			{0.6250, 1.0000, 0.3750},
			{0.6875, 1.0000, 0.3125},
			{0.7500, 1.0000, 0.2500},
			{0.8125, 1.0000, 0.1875},
			{0.8750, 1.0000, 0.1250},
			{0.9375, 1.0000, 0.0625},
			{1.0000, 1.0000, 0.0000},
			{1.0000, 0.9375, 0.0000},
			{1.0000, 0.8750, 0.0000},
			{1.0000, 0.8125, 0.0000},
			{1.0000, 0.7500, 0.0000},
			{1.0000, 0.6875, 0.0000}, 
			{1.0000, 0.6250, 0.0000}, 
			{1.0000, 0.5625, 0.0000},
			{1.0000, 0.5000, 0.0000}, 
			{1.0000, 0.4375, 0.0000},
			{1.0000, 0.3750, 0.0000},
			{1.0000, 0.3125, 0.0000},
			{1.0000, 0.2500, 0.0000},
			{1.0000, 0.1875, 0.0000},
			{1.0000, 0.1250, 0.0000},
			{1.0000, 0.0625, 0.0000},
			{1.0000, 0.0000, 0.0000},
			{0.9375, 0.0000, 0.0000},
			{0.8750, 0.0000, 0.0000},
			{0.8125, 0.0000, 0.0000},
			{0.7500, 0.0000, 0.0000},
			{0.6875, 0.0000, 0.0000},
			{0.6250, 0.0000, 0.0000},
			{0.5625, 0.0000, 0.0000},
			{0.5000, 0.0000, 0.0000}};

  int max_iter = 256, iter;
  double crow, delta;
  int i, j;
  unsigned char R, G, B;
  double x0, y0, x, y, xtemp;

  // Clear the screen and setup a point size. 
  glClear(GL_COLOR_BUFFER_BIT);
  glPointSize(1.0);

  glBegin(GL_POINTS);
  for (i = 1; i <= height; i++) {
	for (j = 1; j <= width; j++) {
		x0 = (xaxis[1] - xaxis[0]) / width * j + xaxis[0];
		y0 = (yaxis[1] - yaxis[0]) / height * i + yaxis[0];
		x = 0.0;
		y = 0.0;
		iter = 0;
		while (((x*x + y*y) <= 4.0) && (iter < max_iter)) {
			xtemp = x*x - y*y + x0;
			y = 2.0*x*y + y0;
			x = xtemp;
			iter++;
		}
		if (iter == max_iter) {
			iter = 0;
		}

	  // Scale color based on max value and interpolated color map
	  crow =  (iter*63)/(max_iter-1);
	  delta = crow - floor(crow);
	
	  R = 255*(cmap[(int)crow][0] + (cmap[(int)crow][0] - cmap[(int)crow+1][0]) * delta);
	  G = 255*(cmap[(int)crow][1] + (cmap[(int)crow][1] - cmap[(int)crow+1][1]) * delta);
	  B = 255*(cmap[(int)crow][2] + (cmap[(int)crow][2] - cmap[(int)crow+1][2]) * delta);
	  glColor3ub(R, G, B);
	  glVertex2i(j-1, i-1);

	}
  }


  glEnd();
  glFlush();
 
}


int main(int argc, char *argv[]) {

   glutInit(&argc, argv);
   glutInitDisplayMode(GLUT_SINGLE | GLUT_RGB);
   glutInitWindowSize(1280, 1024);
   glutCreateWindow("Fractal Generation Program");
   glutDisplayFunc(myDisplay);
   
   glInit();

   glutMainLoop();

   return 0;
}




