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
- (UIImage *) drawObjects: (UIImage *) image :(int*) isFound;
-(void) setView: (GLKView *) view;
-(void) setParams:(GLKBaseEffect*)eff cont:(EAGLContext*)Contextcont width:(double)_width height:(double)_height;
-(void) getValidForwardMoves;
-(void) getValidBackwardMoves;
-(bool) isValidMove:(float) objx :(float) objy;
-(int) tapOnScreen:(float)x :(float) y;
-(int) teamWon;
-(void) initializeCheckerPieces;
-(void) newGame;
-(void) createFramebuffer;
-(void) destroyFrameBuffer;

typedef struct checker {
    double x;
    double y;
    int color;
    bool selected;
    bool crowned;
} checkerPiece;

typedef struct move {
    double x;
    double y;
    int checkersJumped;
} validMove;

@end
