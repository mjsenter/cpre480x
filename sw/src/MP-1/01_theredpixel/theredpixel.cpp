/* -----------------------------------------------------------------------
 * Mike Steffen    (steffma@iastate.edu)
 * Joseph Zambreno (zambreno@iastate.edu)
 * Iowa State University
 * theredpixel.cpp - Draws (what else?) a red pixel
 */


#include <stdio.h>

#include <GL/glut.h>
#include <GL/gl.h>

void glInit()
{
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, 1279, 1023, 0, -1, 1);
    glPointSize(1.0f);
}

void myDisplay()
{
    glClear(GL_COLOR_BUFFER_BIT);

    glColor3ub(255,0,0);
    glBegin(GL_POINTS);
        glVertex2i(640,512); //1024/2-SIZE);
    glEnd();

    glFlush();
}


int main(int argc, char** argv)
{

   glutInit(&argc, argv);
   glutInitDisplayMode(GLUT_SINGLE | GLUT_RGB);
   glutInitWindowSize(1280, 1024);
   glutCreateWindow("The Red Pixel");
   glutDisplayFunc(myDisplay);
   
   glInit();

   glutMainLoop();

   return 0;
}
