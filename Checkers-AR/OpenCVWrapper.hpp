//
//  OpenCVWrapper.h
//  Checkers-AR
//
//  Created by Nikolas Chaconas on 10/23/16.
//  Copyright © 2016 Nikolas Chaconas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface OpenCVWrapper : NSObject <NSCoding>
-(void) finishCalibration;
-(UIImage *) makeMatFromImage: (UIImage *) image;
-(UIImage *) findChessboardCorners:(UIImage *) image1 :(bool) calibrating;
-(int) getBloop;
-(void) setBloop: (int) num;
@end
