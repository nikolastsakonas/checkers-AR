//
//  OpenGLWrapper.h
//  Checkers-AR
//
//  Created by Nikolas Chaconas on 11/6/16.
//  Copyright © 2016 Nikolas Chaconas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES1/gl.h>

@interface OpenGLWrapper : NSObject {
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _colorRenderBuffer;
}

-(void) initOpenGL: (void*)opencv;
- (UIImage *) drawObjects: (UIImage *) image;
-(void) setView: (GLKView *) view;
-(void) setParams:(GLKBaseEffect*)eff cont:(EAGLContext*)Contextcont width:(double)_width height:(double)_height;

@end
