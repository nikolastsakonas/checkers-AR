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
-(UIImage *) makeMatFromImage: (UIImage *) image;
-(UIImage *) findChessboardCorners:(UIImage *) image1 :(bool) calibrating;
-(int) getBloop;
-(bool) checkWait;
-(void) setBloop: (int) num;
-(OpenGLWrapper *) initializeOpenGL;

@end
