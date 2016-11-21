//
//  OpenGLWrapper.m
//  Checkers-AR
//
//  Created by Nikolas Chaconas on 11/6/16.
//  Copyright © 2016 Nikolas Chaconas. All rights reserved.
//

#import "OpenCVWrapper.hpp"
#include <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

#define DEGREES_TO_RADIANS(x) (3.14159265358979323846 * x / 180.0)

@implementation OpenGLWrapper {
    OpenCVWrapper *calibrator;
    GLKView *view;
    GLKBaseEffect *effect;
    EAGLContext * context;
    double width, height, screen_width, screen_height, x, y;
    GLfloat vertices[720];
    GLuint viewRenderBuffer, viewFrameBuffer, colorRenderBuffer, depthRenderBuffer;
    bool wait;
    clock_t prevTimeStamp;
}

-(void) setParams:(GLKBaseEffect*)eff cont:(EAGLContext*)Contextcont width:(double)_width height:(double)_height x:(double)_x y:(double) _y {
    effect = eff;
    context = Contextcont;

    
    GLfloat dim[4];
    glGetFloatv(GL_VIEWPORT, dim);
    
    screen_width = dim[2];
    screen_height = dim[3];
    x = _x;
    y = _y;
    width = _width;
    height = _height;
    
//    width = screen_width;
//    height = screen_height;
    wait = false;
    prevTimeStamp = 0;
    
    std::cout << "width is " << width << " and height is " << height << std::endl;
    
    for (int i = 0; i < 720; i += 2) {
        vertices[i]   = (GLfloat)(cos(DEGREES_TO_RADIANS(i)) * 1);
        vertices[i+1] = (GLfloat)(sin(DEGREES_TO_RADIANS(i)) * 1);
    }
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
    [self createFramebuffer];
}

- (void) createFramebuffer {
    glGenFramebuffers(1, &viewFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, viewFrameBuffer);
    
    glGenRenderbuffers(1, &colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA4, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderBuffer);
    
    glGenRenderbuffers(1, &depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderBuffer);
}

-(bool) checkTimeStamp {
    return (clock() - prevTimeStamp > 20*1e-3*CLOCKS_PER_SEC);
}

-(bool) checkWait {
    if(wait) wait = ![self checkTimeStamp];
    return wait;
}

void drawAxes(float length)
{
    GLfloat vertice[] = {0,0,0,length,0,0};
    
    //x
    glColor4f(1, 0, 0, 1);
    glEnableClientState(GL_VERTEX_ARRAY) ;
    glVertexPointer(3, GL_FLOAT, 0, vertice);
    glDrawArrays(GL_LINES, 0, 3);
    glDisableClientState(GL_VERTEX_ARRAY);
    
    //y
    glColor4f(0, 1, 0, 1);
    vertice[3] = 0; vertice[4] = length;
    glEnableClientState(GL_VERTEX_ARRAY) ;
    glVertexPointer(3, GL_FLOAT, 0, vertice);
    glDrawArrays(GL_LINES, 0, 3);
    glDisableClientState(GL_VERTEX_ARRAY);

    //z
    glColor4f(0, 0, 1, 1);
    vertice[4] = 0; vertice[5] = length;
    glEnableClientState(GL_VERTEX_ARRAY) ;
    glVertexPointer(3, GL_FLOAT, 0, vertice);
    glDrawArrays(GL_LINES, 0, 3);
    glDisableClientState(GL_VERTEX_ARRAY);
}

- (UIImage *) drawObjects: (UIImage *) image :(int*) isFound{
    GLfloat vertice[] = {0,0,0, .5,1,0, 1,0,0};
    GLfloat near = 1.0f, far = 1000.0f;
    
    glClearDepthf( 1.0f );
    glEnable( GL_DEPTH_TEST );
    *isFound = 0;
    //set the viewport

//    glViewport(x, y, width, height);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//    glClearColor(1, 0, 0, 0.3);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
//    [self gluPerspective:90 :1.0 :near :far];
//    glFrustumf(0, width, height, 0, near, far)
    glOrthof(0, (float)width, 0, (float)height, (float)near, (float)far);
    glMultMatrixf(calibrator->persMat);
//    
    bool found = false;
    
    if(![self checkWait]) {
        found = [calibrator findChessboardCornersPlaying: image];
        
        if(!found) {
            wait = true;
            prevTimeStamp = clock();
        } else {
            
            *isFound = 1;
            //for debugging
//            image = [ calibrator drawCorners ];
            
            //use intrinsic parameters to solve pnp and rodrigues
            //this should give us extrinsic parameters
            [calibrator solvePnPRodrigues];
            
            //load in our transformed matrix
            glMatrixMode(GL_MODELVIEW);
            glLoadIdentity();
            glPushMatrix();
            
//            [self gluLookAt:0 :0 :near :0 :0 :0 :0 :1 :0];
            
            [calibrator loadMatrix];
            
            glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
            glEnableClientState(GL_VERTEX_ARRAY);
            glVertexPointer(3, GL_FLOAT, 0, vertice);
            glDrawArrays(GL_TRIANGLES, 0, 3);
            glDisableClientState(GL_VERTEX_ARRAY);
            
            drawAxes(2);
            
            
            [context presentRenderbuffer:GL_RENDERBUFFER];
            glPopMatrix();
        }
    }
    
    return image;
}


-(void) setView: (GLKView *) _view {
    view = (GLKView *)_view;
    std::cout << "\n\n\nsetting view for opengl\n\n\n\n" << std::endl;
}

-(void) initOpenGL: (void*)opencv {
    std::cout << "\n\n\ninitializing openGL\n\n\n" << std::endl;
    calibrator = (__bridge OpenCVWrapper *)opencv;
}

- (void)dealloc {
    if (context == [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext: nil];
    }
    effect = nil;
}


@end
