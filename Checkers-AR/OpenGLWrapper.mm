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
    double width, height;
    GLfloat vertices[720];
    GLuint viewRenderbuffer, viewFramebuffer;
    bool wait;
    clock_t prevTimeStamp;
}

-(void) setParams:(GLKBaseEffect*)eff cont:(EAGLContext*)Contextcont width:(double)_width height:(double)_height {
    effect = eff;
    context = Contextcont;
    width = _width;
    height = _height;
    wait = false;
    prevTimeStamp = 0;
    
    std::cout << "width is " << width << " and height is " << height << std::endl;
    
    for (int i = 0; i < 720; i += 2) {
        vertices[i]   = (GLfloat)(cos(DEGREES_TO_RADIANS(i)) * 1);
        vertices[i+1] = (GLfloat)(sin(DEGREES_TO_RADIANS(i)) * 1);
    }
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    //[self createFramebuffer];
}

//- (void) createFramebuffer {
//    glGenFramebuffers(1, &viewFramebuffer);
//    glGenRenderbuffers(1, &viewRenderbuffer);
//    
//    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
//    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
//    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)view.layer];
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderbuffer);
//    
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, (GLint*)&width);
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, (GLint*)&height);
//}

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

- (UIImage *) drawObjects: (UIImage *) image {
    GLfloat vertice[] = {0,0,-.5, .5,1,-.5, 1,0,-.5};
    GLfloat near = 0.05f, far = 1000.0f;
    GLfloat dim[4];
    glGetFloatv(GL_VIEWPORT, dim);
    //set the viewport
    glViewport(0, 0, dim[2], dim[3]);
    
    glClear(GL_COLOR_BUFFER_BIT);
//    glClearColor(0, 0, 0, 1);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
//    glOrthof(0, dim[2], 0, dim[3], near, far);
//    glMultMatrixf(calibrator->persMat);
    
    
    bool found = false;
    
    if(![self checkWait]) {
        found = [calibrator findChessboardCornersPlaying: image];
        
        if(!found) {
            wait = true;
            prevTimeStamp = clock();
        } else {
            
            //for debugging
            image = [ calibrator drawCorners ];
            
            //use intrinsic parameters to solve pnp and rodrigues
            //this should give us extrinsic parameters
            [calibrator solvePnP];
            
            [calibrator solveRodrigues];
            
            //load in our transformed matrix
            glMatrixMode(GL_MODELVIEW);
            glLoadIdentity();
            
//            [calibrator loadMatrix];
            glPushMatrix();
            
            glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
            glEnableClientState(GL_VERTEX_ARRAY);
            glVertexPointer(3, GL_FLOAT, 0, vertice);
            glDrawArrays(GL_TRIANGLES, 0, 3);
            glDisableClientState(GL_VERTEX_ARRAY);
            
//            drawAxes(.5);
            
            glPopMatrix();
            [context presentRenderbuffer:GL_RENDERBUFFER];
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
