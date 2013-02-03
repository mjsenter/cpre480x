#include <stdio.h>

#include <GL/glut.h>
#include <GL/gl.h>

void glInit()
{
    glClearColor(0.0f, 0.0f, 1.0f, 0.0f);
    glColor3f(1.0f, 1.0f, 1.0f);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, 1280, 1024, 0, -1, 1);
}

void myDisplay()
{
    glClear(GL_COLOR_BUFFER_BIT);
    glPointSize(1.0);
    glColor3f(1.0f, 0.0f, 0.0f);
  
    glBegin(GL_POINTS);
      glVertex2i(1,1);
    glEnd();

    glBegin(GL_POINTS);
 	for(unsigned int i = 0; i < 1280/2; i++) {
	    glVertex2i(i, 1);
	    glVertex2i(i,1024/2);
	}
	for(unsigned int i = 0; i < 1024/2; i++) {
	    glVertex2i(0, i);
	    glVertex2i(1280/2, i);
	}
    glEnd();

   glColor3f(0.0f, 1.0f, 0.0f);

    glBegin(GL_POINTS);
        for(unsigned int i = 1280/2+1; i < 1280; i++) {
            glVertex2i(i, 1);
            glVertex2i(i,1024/2);
        }
        for(unsigned int i = 0; i < 1024/2; i++) {
            glVertex2i(1280-1, i);
            glVertex2i(1280/2+1, i);
        }
    glEnd();
 
   glColor3f(0.0f, 0.0f, 1.0f);

    glBegin(GL_POINTS);
        for(unsigned int i = 0; i < 1280/2; i++) {
            glVertex2i(i, 1024/2+1);
            glVertex2i(i,1024);
        }
        for(unsigned int i = 1024/2+1; i < 1024; i++) {
            glVertex2i(0, i);
            glVertex2i(1280/2, i);
        }
    glEnd();

    glColor3f(1.0f, 1.0f, 0.0f);

    glBegin(GL_POINTS);
        for(unsigned int i = 1280/2+1; i < 1280; i++) {
            glVertex2i(i, 1024/2+1);
            glVertex2i(i,1024);
        }
        for(unsigned int i = 1024/2+1; i < 1024; i++) {
            glVertex2i(1280/2+2, i);
            glVertex2i(1280-1, i);
        }
    glEnd();

   glFlush();
}


int main(int argc, char** argv)
{

   glutInit(&argc, argv);
   glutInitDisplayMode(GLUT_SINGLE | GLUT_RGB);
   glutInitWindowSize(1280, 1024);
   glutCreateWindow("SGL point test");
   glutDisplayFunc(myDisplay);
   
   glInit();

   glutMainLoop();

   return 0;
}
