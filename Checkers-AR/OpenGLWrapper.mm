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
#import <OpenGLES/ES1/gl.h>

#define DEGREES_TO_RADIANS(x) (3.14159265358979323846 * x / 180.0)

@implementation OpenGLWrapper {
    OpenCVWrapper *calibrator;
    GLKView *view;
    GLKBaseEffect *effect;
    EAGLContext * context;
    double width, height;
    GLfloat vertices[720];
    GLuint viewRenderbuffer, viewFramebuffer;
}

-(void) setParams:(GLKBaseEffect*)eff cont:(EAGLContext*)Contextcont width:(double)_width height:(double)_height {
    effect = eff;
    context = Contextcont;
    width = _width;
    height = _height;
    
    std::cout << "width is " << width << " and height is " << height << std::endl;
    
    for (int i = 0; i < 720; i += 2) {
        vertices[i]   = (GLfloat)(cos(DEGREES_TO_RADIANS(i)) * 1);
        vertices[i+1] = (GLfloat)(sin(DEGREES_TO_RADIANS(i)) * 1);
    }
    //[self createFramebuffer];
}

- (void) createFramebuffer {
    glGenFramebuffers(1, &viewFramebuffer);
    glGenRenderbuffers(1, &viewRenderbuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)view.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderbuffer);
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, (GLint*)&width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, (GLint*)&height);
}

- (void) drawObjects {
    GLfloat near = 0.05f, far = 1000.0;
//    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    
    glViewport(0, 0, (GLsizei)width, (GLsizei)height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof(0, (GLfloat)width, 0, (GLfloat)height, near, far);
//    glMultMatrixf(calibrator->persMat);
    
    //put semi-transparent film
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1, 0.5, 0.5, 0.2);
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();


    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glEnable(GL_VERTEX_ARRAY);
    
    glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
    
    glDrawArrays(GL_TRIANGLES, 0, 360);
    
//    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
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
