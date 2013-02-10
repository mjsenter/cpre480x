
#include <GL/glut.h>
#include <stdio.h>
#include <math.h>

#define PI 3.14159265
#define DEG2RAD (PI/180.0)

int spiralTypes[4][4] = { { 0, 90, 180, 270 }, { 0, 30, 60, 90 }, { 0, -90, -180, -270 }, { 0, -30, -60, -90 } };
int spiralType = 0;

typedef struct _spiralPoint {
	float amp;
	float angle;
} spiralPoint;

typedef struct _spiralPointList {
	_spiralPointList * next;
	spiralPoint * point;
} spiralPointList;

typedef struct _spiral {
	spiralPointList *spl;
	float dx;
	float damp;
	int reset;
	int count;
	float **colors;
	int numColors;
	int colorIndex;
	char draw;
	float angleOffset;
	float ampOffset;
} spiral;

typedef struct _spiralSet {
	spiral * s1;
	spiral * s2;
	spiral * s3;
	spiral * s4;
	float center[2];
} spiralSet;

typedef struct _spiralList {
	struct _spiralList *next;
	spiralSet * ss;
} spiralList;

spiralList * ss1;

spiralPointList * initSpiralPointList( float angleOff, float ampOff ) {
	spiralPointList * ret = (spiralPointList *)malloc( sizeof( spiralPointList ) );
	ret->next = 0;
	ret->point = (spiralPoint *)malloc( sizeof( spiralPoint ) );
	ret->point->amp = ampOff;
	ret->point->angle = angleOff;
	return ret;
}

spiral * initSpiral( float dx, float damp, int reset, float **colors, int numColors, char draw, float angleOff, float ampOff ) {
	spiral * ret = (spiral *)malloc( sizeof( spiral ) );
	ret->spl = initSpiralPointList( angleOff, ampOff );
	ret->count = 0;
	ret->dx = dx;
	ret->damp = damp;
	ret->reset = reset;
	ret->colors = colors;
	ret->numColors = numColors;
	ret->colorIndex = 0;
	ret->draw = draw;
	ret->angleOffset = angleOff;
	ret->ampOffset = ampOff;
	return ret;
}

spiralSet * initSpiralSet( float *origin, int type ) {
	float **line1 = (float**)malloc( sizeof( float* ) * 2 );
	line1[0] = (float*)malloc( sizeof( float ) * 3 );
	line1[1] = (float*)malloc( sizeof( float ) * 3 );

	line1[0][0] = 1.0;
	line1[0][1] = 0.0;
	line1[0][2] = 0.2;

	line1[1][0] = 0.5;
	line1[1][1] = 1.0;
	line1[1][2] = 0.5;


	float **line2 = (float**)malloc( sizeof( float* ) * 2 );
	line2[0] = (float*)malloc( sizeof( float ) * 3 );
	line2[1] = (float*)malloc( sizeof( float ) * 3 );

	line2[0][0] = 1.0;
	line2[0][1] = 0.7;
	line2[0][2] = 0.0;

	line2[1][0] = 0.3;
	line2[1][1] = 0.0;
	line2[1][2] = 0.8;


	float **line3 = (float**)malloc( sizeof( float* ) * 2 );
	line3[0] = (float*)malloc( sizeof( float ) * 3 );
	line3[1] = (float*)malloc( sizeof( float ) * 3 );

	line3[0][0] = 1.0;
	line3[0][1] = 0.7;
	line3[0][2] = 1.0;

	line3[1][0] = 0.3;
	line3[1][1] = 1.0;
	line3[1][2] = 0.8;


	float **line4 = (float**)malloc( sizeof( float* ) * 2 );
	line4[0] = (float*)malloc( sizeof( float ) * 3 );
	line4[1] = (float*)malloc( sizeof( float ) * 3 );

	line4[0][0] = 0.2;
	line4[0][1] = 0.7;
	line4[0][2] = 1.0;

	line4[1][0] = 1.0;
	line4[1][1] = 0.5;
	line4[1][2] = 1.0;

	spiralSet * set = (spiralSet *)malloc( sizeof( spiralSet ) );
	set->center[0] = origin[0];
	set->center[1] = origin[1];
	float dx = 1;
	if( type > 1 ) {
		dx = -1;
	}
	set->s1 = initSpiral( dx*.01, .001, 10, line1, 2, 1, spiralTypes[spiralType][0], 0 );
	set->s2 = initSpiral( dx*.01, .001, 10, line2, 2, 1, spiralTypes[spiralType][1], 0 );
	set->s3 = initSpiral( dx*.01, .001, 10, line3, 2, 1, spiralTypes[spiralType][2], 0 );
	set->s4 = initSpiral( dx*.01, .001, 10, line4, 2, 1, spiralTypes[spiralType][3], 0 );
	return set;
}

void resetSpiral( spiral *s ) {
	spiralPointList *spl = initSpiralPointList( s->angleOffset, s->ampOffset );
	spl->next = s->spl;
	s->spl = spl;

	s->colorIndex++;
	if( s->colorIndex >= s->numColors ) {
		s->colorIndex = 0;
	}
}

//void resetSpiralSet( spiralSet *s ) {
//	resetSpiral( s->s1, 0 );
//	resetSpiral( s->s2, 0 );
//	resetSpiral( s->s3, 0 );
//	resetSpiral( s->s4, 0 );
//}

void updateSpiral( spiral *s ) {
	if( s->draw ) {
		spiralPointList *spl = s->spl;
		while( spl != 0 ) {
			spl->point->angle += atan(s->dx/spl->point->amp) / DEG2RAD;
			if( spl->point->angle >= 360 ) {
				spl->point->angle -= 360;
			}
			spl->point->amp += s->damp;
			spl = spl->next;
		}
		s->count++;
		if( s->count >= s->reset ) {
			s->count = 0;
			resetSpiral( s );
		}
	}
}

void updateSpiralSet( spiralSet *ss ) {
	updateSpiral( ss->s1 );
	updateSpiral( ss->s2 );
	updateSpiral( ss->s3 );
	updateSpiral( ss->s4 );
}

int elapsedTime;

// frame rate in millis for 30 frames/sec
const int frameRate = 1000.0 / 60;

char redraw = 0;

void drawSpiral( spiral * s, float center[2] ) {
	if( s->draw ) {
		spiralPointList * temp = s->spl;
		while( temp != 0 ) {
			glLoadIdentity();
			glTranslatef( center[0], center[1], 0 );
			glRotatef( temp->point->angle, 0, 0, 10 );
			glTranslatef( 0, temp->point->amp, 0 );

			glBegin( GL_POINTS );
			glColor3fv( s->colors[s->colorIndex] );
			glVertex3f( 0, 0, 0 );
			glEnd();
			temp = temp->next;
		}
	}
}

void drawSpiralSet( spiralSet * ss ) {
	drawSpiral( ss->s1, ss->center );
	drawSpiral( ss->s2, ss->center );
	drawSpiral( ss->s3, ss->center );
	drawSpiral( ss->s4, ss->center );
}

void display( void ) {
	if( redraw ) {
		redraw = 0;
		glClear( GL_COLOR_BUFFER_BIT );
	}
	spiralList * temp = ss1;
	do {
		drawSpiralSet( temp->ss );
		temp = temp->next;
	} while( temp != 0 );

	glFlush();
}

void init() {
	float center[] = { 0, 0 };
	ss1 = (spiralList *)malloc( sizeof( spiralList ) );
	ss1->next = 0;
	ss1->ss = initSpiralSet( center, spiralType );
}

void idle() {
	int now = glutGet(GLUT_ELAPSED_TIME);
	if (now - elapsedTime > frameRate)
	{
		elapsedTime = now;

		spiralList * temp = ss1;
		do {
			updateSpiralSet( temp->ss );
			temp = temp->next;
		} while( temp != 0 );

		glutPostRedisplay();
	}
}

void freeSpiral( spiral *s ) {
	int i;
	for( i = 0; i < s->numColors; i++ ) {
		free( s->colors[i] );
	}
	free( s->colors );
	free( s );
}

void freeSpiralSet( spiralSet *ss ) {
	freeSpiral( ss->s1 );
	freeSpiral( ss->s2 );
	freeSpiral( ss->s3 );
	freeSpiral( ss->s4 );
}

void mouse( int button, int state, int x, int y ) {
	if ( state == GLUT_DOWN ) {
		spiralList * temp = ss1;
		switch( button ) {
			case GLUT_RIGHT_BUTTON:
				redraw = 1;
				do {
					freeSpiralSet( ss1->ss );
					ss1 = ss1->next;
					free( temp );
					temp = ss1;
				} while( temp != 0 );

			case GLUT_LEFT_BUTTON:
				float center[] = { (float)x/(float)glutGet(GLUT_WINDOW_WIDTH) * 2 - 1.0, (float)y/(float)glutGet(GLUT_WINDOW_HEIGHT) * -2 + 1.0 };
				spiralList * n = (spiralList *)malloc( sizeof( spiralList ) );
				n->next = ss1;
				n->ss = initSpiralSet( center, spiralType );
				ss1 = n;

				break;
		}
	}
}

void keyboard( unsigned char key, int x, int y ) {
	spiralType++;
	if( spiralType == 4 ) {
		spiralType = 0;
	}
}

int main(int argc, char **argv)
{
	glutInit(&argc, argv);
	glutInitDisplayMode( GLUT_RGBA );
	glutInitWindowSize(512, 512);
	glutCreateWindow("Example 0");

	init();

	glClearColor(.1, .1, .1, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);

	glutKeyboardFunc( keyboard );
	glutMouseFunc( mouse );
	glutDisplayFunc(display);
	glutIdleFunc( idle );
	glutMainLoop();
	return 0;	
}

