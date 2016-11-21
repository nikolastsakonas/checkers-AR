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
#define NUM_CHECKER_PIECES 11

@implementation OpenGLWrapper {
    OpenCVWrapper *calibrator;
    GLKView *view;
    GLKBaseEffect *effect;
    EAGLContext * context;
    double width, height, screen_width, screen_height, x, y;
    
    GLuint viewRenderBuffer, viewFrameBuffer, colorRenderBuffer, depthRenderBuffer;
    bool wait;
    clock_t prevTimeStamp;
    std::vector<checkerPiece> grayPieces;
    std::vector<checkerPiece> redPieces;
}

-(void) setParams:(GLKBaseEffect*)eff cont:(EAGLContext*)Contextcont width:(double)_width height:(double)_height {
    effect = eff;
    context = Contextcont;

    width = _width;
    height = _height;
    
    wait = false;
    prevTimeStamp = 0;
    
    std::cout << "width is " << width << " and height is " << height << std::endl;

    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
    [self initializeCheckerPieces];
//    [self createFramebuffer];
}

- (void) initializeCheckerPieces {
    checkerPiece gray;
    checkerPiece red;
    for(int i = 0; i < 4; i++) {
        gray.x = -1 + i*2;
        gray.y = -1;
        gray.color = 0;
        red.x = -1 + i*2;
        red.y = 7;
        red.color = 1;
        redPieces.push_back(red);
        grayPieces.push_back(gray);
    }
    
    for(int i = 0; i < 3; i++) {
        gray.x = i*2;
        gray.y = 0;
        gray.color = 0;
        red.x = i*2;
        red.y = 6;
        red.color = 1;
        redPieces.push_back(red);
        grayPieces.push_back(gray);
    }
    
    for(int i = 0; i < 4; i++) {
        gray.x = -1 + i*2;
        gray.y = 1;
        gray.color = 0;
        red.x = -1 + i*2;
        red.y = 5;
        red.color = 1;
        redPieces.push_back(red);
        grayPieces.push_back(gray);
    }
    [self printCheckerPieces];
}

- (void) printCheckerPieces {
    std::cout << "\n------Red Pieces------\n" << std::endl;
    for(int i = 0; i < NUM_CHECKER_PIECES; i++) {
        std::cout << "x:" << redPieces.at(i).x;
        std::cout << " y:" << redPieces.at(i).y;
        std::cout << " color:" << redPieces.at(i).color << "\n" << std::endl;
    }
    std::cout << "\n------Black Pieces------\n" << std::endl;
    for(int i = 0; i < NUM_CHECKER_PIECES; i++) {
        std::cout << "x:" << grayPieces.at(i).x;
        std::cout << " y:" << grayPieces.at(i).y;
        std::cout << " color:" << grayPieces.at(i).color << "\n" << std::endl;
    }
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

- (void) drawCheckerPiece: (checkerPiece) piece {
    GLfloat vertice[720];
    double z;
    for(z = 0; z > -0.5; z-=0.1) {
        glTranslatef(0, 0, z);
        for (int i = 0; i < 720; i += 2) {
            vertice[i]   = (GLfloat)(cos(DEGREES_TO_RADIANS(i)) * 0.38) + piece.x + 0.5;
            vertice[i+1] = (GLfloat)(sin(DEGREES_TO_RADIANS(i)) * 0.38) + piece.y + 0.5;
        }
        
        if(piece.color == 0) {
            glColor4f(0.7f, 0.7f, 0.7f, 1.0f);
        } else {
            glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
        }
        
        glEnableClientState(GL_VERTEX_ARRAY);
        glVertexPointer(2, GL_FLOAT, 0, vertice);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 360);
        glDisableClientState(GL_VERTEX_ARRAY);
        glTranslatef(0, 0, -z);
    }
}

- (UIImage *) drawObjects: (UIImage *) image :(int*) isFound{
    GLfloat near = 1.0f, far = 1000.0f;
    
    glClearDepthf( 1.0f );
    glEnable( GL_DEPTH_TEST );
    *isFound = 0;
    //set the viewport
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    glOrthof(0, (float)width, 0, (float)height, (float)near, (float)far);
    glMultMatrixf(calibrator->persMat);
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
            
            [calibrator loadMatrix];
            
            for(int i = 0; i < NUM_CHECKER_PIECES; i++) {
                [self drawCheckerPiece :grayPieces.at(i)];
            }
            
            for(int i = 0; i < NUM_CHECKER_PIECES; i++) {
                [self drawCheckerPiece :redPieces.at(i)];
            }
            
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
