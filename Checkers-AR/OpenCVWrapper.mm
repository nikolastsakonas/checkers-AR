//
//  OpenCVWrapper.m
//  Checkers-AR
//
//  Created by Nikolas Chaconas on 10/23/16.
//  Copyright © 2016 Nikolas Chaconas. All rights reserved.
//

#import "OpenCVWrapper.hpp"
#include <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
//unfortunately need to do this to hide all opencv calls from swift
//otherwise I would put these in .hpp
@implementation OpenCVWrapper {
    cv::Mat cameraMatrix;
    cv::Mat distCoeffs;
    int bloop;
    std::vector<std::vector<cv::Point2f>> imagePoints;
    std::vector<std::vector<cv::Point3f>> objectPoints;
    cv::Size boardSize;
    cv::Size imageSize;
    std::vector<cv::Mat> rvecs, tvecs;
    double fovx, fovy, focalLength, aspectRatio;
    cv::Point2d principalPoint;
    double fx, fy, cx, cy;
    double persMat[16];
    double d0, d1, d2, d3;
}

-(int) getBloop {
    return bloop;
}

-(void) setBloop: (int) num {
    bloop = num;
}
//this will come in handy
-(UIImage *) makeMatFromImage: (UIImage *) image {
    cv::Mat imageMat;
    UIImageToMat(image, imageMat);
    //can do all sorts of stuff with the MAT
    //and then convert it back to UIImage for use in swift
    return MatToUIImage(imageMat);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        std::cout << "going!!!!!" << std::endl;
        int squareSize = 1;
        objectPoints.push_back(std::vector <cv::Point3f> ());
        for( int i = 0; i < 6; ++i )
            for( int j = 0; j < 6; ++j )
                objectPoints[0].push_back(cv::Point3f(double( j*squareSize ), double( i*squareSize ), 0));
        boardSize = cv::Size(6,6);
        cameraMatrix = cv::Mat::eye(3, 3, CV_64F);
        distCoeffs = cv::Mat::zeros(4, 1, CV_64F);
    }
    return self;
}

-(UIImage*) findChessboardCorners:(UIImage*) image1 {
    cv::Mat image;
    UIImageToMat(image1, image);
    
    //need to rotate image 90 degrees because
    //for some reason its sideways...
    cv::Point2f src_center(image.cols/2.0F, image.rows/2.0F);
    cv::Mat Rot = getRotationMatrix2D(src_center, -90.0, 1.0);
    cv::Mat dst;
    cv::warpAffine(image, image, Rot, image.size());
    
    std::vector<cv::Point2f> corners;
    std::cout << "board size is " << boardSize;
    bool found = findChessboardCorners(image, boardSize, corners, CV_CALIB_CB_ADAPTIVE_THRESH + CV_CALIB_CB_NORMALIZE_IMAGE);
    
    if(found) {
        std::cout << "\nimage found\n" << std::endl;
        imageSize = image.size();
        cv::Mat tempView;
        cvtColor(image, tempView, cv::COLOR_BGR2GRAY);
        cornerSubPix( tempView, corners, cv::Size(3,3),
                     cv::Size(-1,-1), cv::TermCriteria( CV_TERMCRIT_EPS+CV_TERMCRIT_ITER, 30, 0.1));
        
        imagePoints.push_back(corners);
    }

    cv::drawChessboardCorners(image, boardSize, corners, true);

    return MatToUIImage(image);
}



-(void) createPerspectiveMatrix {
    double near = 0.05f, far = 1000.0;
    fx = cameraMatrix.at<double>(0,0);
    fy = cameraMatrix.at<double>(1,1);
    cx = principalPoint.x;
    cy = principalPoint.y;
    
    
    // Matrix used for perspective
    // built using intrinsic parameters
    //does NOT depend on the scene viewed
    //basically transposed the intrinsic parameters matrix
    //and normalized it to device coordinates using glortho
    //negated third column because camera looks down the negative-z axis
    //and then transposed it to get into opengl row major
    
    persMat[0] = fx;
    persMat[8] = -cx;
    persMat[5] = fy;
    persMat[9] = -cy;
    persMat[10] = near + far;
    persMat[14] = near * far;
    persMat[11] = -1.0f;
}

//rebuild camera matrix
-(void) createCameraMatrix {
    cameraMatrix.at<double>(0,0) = fx;
    cameraMatrix.at<double>(1,1) = fy;
    cameraMatrix.at<double>(0,2) = cx;
    cameraMatrix.at<double>(1,2) = cy;
}

//rebuild camera matrix
-(void) createDistMatrix {
    distCoeffs.at<double>(0,0) = d0;
    distCoeffs.at<double>(1,0) = d1;
    distCoeffs.at<double>(2,0) = d2;
    distCoeffs.at<double>(3,0) = d3;
}

//this will store all of the final calibration values
-(void) finishCalibration {
    objectPoints.resize(imagePoints.size(),objectPoints[0]);
    
    cv::calibrateCamera(objectPoints, imagePoints, imageSize, cameraMatrix,
                        distCoeffs, rvecs, tvecs, CV_CALIB_FIX_K4|CV_CALIB_FIX_K5);
    
    cv::calibrationMatrixValues(self->cameraMatrix, imageSize, 0.0f, 0.0f, fovx, fovy, focalLength, principalPoint, aspectRatio);

    [self createPerspectiveMatrix];
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    d0 = distCoeffs.at<double>(0,0);
    d1 = distCoeffs.at<double>(1,0);
    d2 = distCoeffs.at<double>(2,0);
    d3 = distCoeffs.at<double>(3,0);
    
    //bloop for debugging
    [aCoder encodeInt:bloop forKey:@"bloop"];
    
    //persMat
    [aCoder encodeDouble:fx forKey:@"fx"];
    [aCoder encodeDouble:fy forKey:@"fy"];
    [aCoder encodeDouble:cx forKey:@"cx"];
    [aCoder encodeDouble:cy forKey:@"cy"];
    
    //distCoef
    [aCoder encodeDouble:d0 forKey:@"d0"];
    [aCoder encodeDouble:d1 forKey:@"d1"];
    [aCoder encodeDouble:d2 forKey:@"d2"];
    [aCoder encodeDouble:d3 forKey:@"d3"];
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [self init];
    //bloop for debugging
    bloop = [aDecoder decodeIntForKey:@"bloop"];
    
    //persMat
    fx = [aDecoder decodeDoubleForKey:@"fx"];
    fy = [aDecoder decodeDoubleForKey:@"fy"];
    cx = [aDecoder decodeDoubleForKey:@"cx"];
    cy = [aDecoder decodeDoubleForKey:@"cy"];
    
    //distCoef
    d0 = [aDecoder decodeDoubleForKey:@"fx"];
    d1 = [aDecoder decodeDoubleForKey:@"fy"];
    d2 = [aDecoder decodeDoubleForKey:@"cx"];
    d3 = [aDecoder decodeDoubleForKey:@"cy"];
    
    [self createPerspectiveMatrix];
    [self createCameraMatrix];
    [self createDistMatrix];
    return self;
}
@end
