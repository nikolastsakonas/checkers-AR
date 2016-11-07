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

@implementation OpenGLWrapper {
    OpenCVWrapper *calibrator;
}

-(void) initOpenGL: (void*)opencv {
    std::cout << "initializing openGL" << std::endl;
    calibrator = (__bridge OpenCVWrapper *)opencv;
    std::cout << [calibrator getBloop] << std::endl;
    
}

@end
