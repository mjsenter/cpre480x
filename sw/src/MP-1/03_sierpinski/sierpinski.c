/* -----------------------------------------------------------------------
 * Mike Steffen    (steffma@iastate.edu)  
 * Joseph Zambreno (zambreno@iastate.edu)
 * Iowa State University
 * sierpinski.c - Draws a 2D Sierpinski gasket
*/

#include <stdio.h>
#include <GL/glut.h>


void glInit() {
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glColor3ub(0, 250, 0);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, 1280, 1024, 0, -1, 1);
}

void myDisplay() {

  GLfloat vertices[3][2] = {{0, 1023}, {639,0}, {1279,1023}}; 
  int i, j, k;

  srand(time(0));
  glClear(GL_COLOR_BUFFER_BIT);
  GLfloat p[2] = {640, 512};

  glBegin(GL_POINTS);
  for (k = 0; k < 75000; k++) {
    //printf("iteration %i\n", k);
    j = rand()%3;
    p[0] = (p[0]+vertices[j][0]) / 2.0;
    p[1] = (p[1]+vertices[j][1]) / 2.0;
    glVertex2fv(p);
  }

  glEnd();
  glFlush();
 
}


int main(int argc, char *argv[]) {

   glutInit(&argc, argv);
   glutInitDisplayMode(GLUT_SINGLE | GLUT_RGB);
   glutInitWindowSize(1280, 1024);
   glutCreateWindow("Sierpinski Gasket");
   glutDisplayFunc(myDisplay);
   
   glInit();

   glutMainLoop();

   return 0;
}




