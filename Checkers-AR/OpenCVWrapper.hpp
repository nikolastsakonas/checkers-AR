//
//  OpenCVWrapper.h
//  Checkers-AR
//
//  Created by Nikolas Chaconas on 10/23/16.
//  Copyright © 2016 Nikolas Chaconas. All rights reserved.
//

#import "OpenGLWrapper.hpp"

@interface OpenCVWrapper : NSObject <NSCoding> {
    @public float persMat[16];
}
-(void) finishCalibration;
-(UIImage *) findChessboardCorners:(UIImage *) image1;
-(bool) findChessboardCornersPlaying:(UIImage *) image1;
-(void) solvePnPRodrigues;
-(int) getBloop;
-(void) setBloop: (int) num;
-(void) loadMatrix;
-(UIImage *) flipImage: (UIImage *) image1;
-(UIImage *) drawCorners;
-(bool) findPlaceOnCheckerboard:(float)xx :(float)yy :(int*)objx :(int*)objy ;
-(OpenGLWrapper *) initializeOpenGL;
-(UIImage *) drawTurnRectangle :(int) turn;

typedef struct b {
    float x;
    float y;
    float boardX;
    float boardY;
}BoardCorners;
@end
