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
    double d0, d1, d2, d3;
    bool wait;
    std::vector<cv::Point3f> objectCoordinates;
    cv::Mat TMat;
    std::vector<cv::Point2f> currentCorners;
    cv::Mat currentImage;
}

-(int) getBloop {
    return bloop;
}

-(void) setBloop: (int) num {
    bloop = num;
}
//this will come in handy
//-(UIImage *) makeMatFromImage: (UIImage *) image {
//    cv::Mat imageMat;
//    UIImageTddddoMat(image, imageMat);
//    //can do all sorts of stuff with the MAT
//    //and then convert it back to UIImage for use in swift
//    return MatToUIImage(imageMat);
//}

- (instancetype)init
{
    self = [super init];
    if (self) {
        int squareSize = 1;
        boardSize = cv::Size(6,8);
        objectPoints.push_back(std::vector <cv::Point3f> ());
        for( int i = 0; i < boardSize.height; ++i )
            for( int j = 0; j < boardSize.width; ++j )
                objectPoints[0].push_back(cv::Point3f(double( j*squareSize ), double( i*squareSize ), 0));
        
        //create coordinate axis (0,0,0), (squareSize,0,0)...etc
        for( int i = 0; i < boardSize.height; ++i ) {
            for( int j = 0; j < boardSize.width; ++j ) {
                objectCoordinates.push_back(cv::Point3f(double( j*squareSize ), double( i*squareSize ), 0));
            }
        }
        
        for( int i = 0; i < 16; i ++ ) {
            persMat[i] = 0;
        }
        
        TMat = cv::Mat(4, 4, CV_64F);
        cameraMatrix = cv::Mat::eye(3, 3, CV_64F);
        distCoeffs = cv::Mat::zeros(4, 1, CV_64F);
        wait = false;
    }
    return self;
}

-(UIImage *) drawCorners {
    cv::Mat image = currentImage;
    
    cv::drawChessboardCorners(image, boardSize, currentCorners, true);
    cv::circle(image, cv::Point(0,0), 10, cv::Scalar(1,0,0,1));
    
    
    cv::Point point; point.x = 0; point.y = 10;
    
    cv::circle(image, point, 10, cv::Scalar(1,0,0,1));
    
    cv::cvtColor(image, image, CV_BGR2RGB);
    return MatToUIImage(image);
}


-(bool) findChessboardCornersPlaying:(UIImage*) image1 {
    cv::Mat image, tempView;
    image = [self imageToMat:image1];
    
    cv::cvtColor(image, image, CV_RGB2BGR);

    int found = cv::findChessboardCorners(image, boardSize, currentCorners, CV_CALIB_CB_ADAPTIVE_THRESH);
    
    currentImage = image.clone();
    return found;
}

-(void) loadMatrix {
    TMat.convertTo(TMat, CV_32F);
    glLoadMatrixf(&TMat.at<float>(0,0));
}

-(void) solvePnPRodrigues {
    cv::Mat rvec, tvec;
    cv::solvePnP(objectCoordinates, currentCorners, cameraMatrix, distCoeffs, rvec, tvec);
    
    cv::Mat rotationMat;
    cv::Rodrigues(rvec, rotationMat);
    TMat = cv::Mat(4, 4, CV_64F);
    
    //Transformation Matrix
    TMat( cv::Range(0,3), cv::Range(0,3)) = rotationMat * 1;
    TMat( cv::Range(0,3), cv::Range(3,4) ) = tvec * 1;
    
    //add row of 0, 0, 0, 1
    TMat.at<double>(3,0) = 0.0f;
    TMat.at<double>(3,1) = 0.0f;
    TMat.at<double>(3,2) = 0.0f;
    TMat.at<double>(3,3) = 1.0f;
    
    cv::Mat RotMat = cv::Mat::zeros(4, 4, CV_64F);
    RotMat.at<double>(0,0) = 1.0f;
    RotMat.at<double>(1,1) = -1.0f;
    RotMat.at<double>(2,2) = -1.0f;
    RotMat.at<double>(3,3) = 1.0f;
    
    // AND transpose the matrix
    // OpenCv uses both a different coordinate system
    // and column major order...
    
    TMat = (RotMat * TMat).t();
}

-(UIImage *) flipImage: (UIImage *) image1 {
    cv::Mat image;
    UIImageToMat(image1, image);
    
    //flip mat 90 degrees clockwise;
    cv::Point2f src_center(image.cols/2.0F, image.rows/2.0F);
    cv::Mat Rot = getRotationMatrix2D(src_center, -90.0, 1.0);
    cv::Mat dst;
    cv::warpAffine(image, image, Rot, image.size());
    
    return MatToUIImage(image);
}

-(cv::Mat) imageToMat:(UIImage*) image1 {
    cv::Mat image;
    UIImageToMat(image1, image);
    
    //flip mat 90 degrees clockwise;
//    cv::Point2f src_center(image.cols/2.0F, image.rows/2.0F);
//    cv::Mat Rot = getRotationMatrix2D(src_center, -90.0, 1.0);
//    cv::Mat dst;
//    cv::warpAffine(image, image, Rot, image.size());

    return image;
}

-(UIImage*) findChessboardCorners:(UIImage*) image1 {
    cv::Mat image;
    
    image = [self imageToMat:image1];
    cv::cvtColor(image, image, CV_RGB2BGR);
    
    std::vector<cv::Point2f> corners;
    bool found = false;
    found = findChessboardCorners(image, boardSize, corners, CV_CALIB_CB_ADAPTIVE_THRESH + CV_CALIB_CB_NORMALIZE_IMAGE);
    
    if(found) {
        imageSize = image.size();
        cv::Mat tempView;
        cvtColor(image, tempView, cv::COLOR_BGR2GRAY);
        cornerSubPix( tempView, corners, cv::Size(3,3),
                     cv::Size(-1,-1), cv::TermCriteria( CV_TERMCRIT_EPS+CV_TERMCRIT_ITER, 30, 0.1));
        
        imagePoints.push_back(corners);
        cv::drawChessboardCorners(image, boardSize, corners, true);
    }
    
    cvtColor(image, image, CV_BGR2RGB);
    return MatToUIImage(image);
}



-(void) createPerspectiveMatrix {
    double near = 0.05f, far = 1000.0f;
    
    
    // Matrix used for perspective
    // built using intrinsic parameters
    //does NOT depend on the scene viewed
    //basically transposed the intrinsic parameters matrix
    //and normalized it to device coordinates using glortho
    //negated third column because camera looks down the negative-z axis
    //and then transposed it to get into opengl row major
    
    persMat[0] = (float)fx;
    persMat[8] = (float)-cx;
    persMat[5] = (float)fy;
    persMat[9] = (float)-cy;
    persMat[10] = (float)(near + far);
    persMat[14] = (float)(near * far);
    persMat[11] = -1.0f;
}

//rebuild camera matrix
-(void) createCameraMatrix {
    cameraMatrix.at<double>(0,0) = fx;
    cameraMatrix.at<double>(1,1) = fy;
    cameraMatrix.at<double>(0,2) = cx;
    cameraMatrix.at<double>(1,2) = cy;
    std::cout << "Camera Matrix:" << std::endl;
    std::cout << cameraMatrix << std::endl;
}

//rebuild camera matrix
-(void) createDistMatrix {
    distCoeffs.at<double>(0,0) = d0;
    distCoeffs.at<double>(1,0) = d1;
    distCoeffs.at<double>(2,0) = d2;
    distCoeffs.at<double>(3,0) = d3;
    std::cout << "Dist Matrix:" << std::endl;
    std::cout << distCoeffs << std::endl;
}

//this will store all of the final calibration values
-(void) finishCalibration {
    objectPoints.resize(imagePoints.size(),objectPoints[0]);
    
    cv::calibrateCamera(objectPoints, imagePoints, imageSize, cameraMatrix,
                        distCoeffs, rvecs, tvecs, CV_CALIB_FIX_K4|CV_CALIB_FIX_K5);
    
    cv::calibrationMatrixValues(cameraMatrix, imageSize, 0.0f, 0.0f, fovx, fovy, focalLength, principalPoint, aspectRatio);
    
    fx = cameraMatrix.at<double>(0,0);
    fy = cameraMatrix.at<double>(1,1);
    cx = principalPoint.x;
    cy = principalPoint.y;
    
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
    std:: cout << "initing with coder" << std::endl;
    self = [self init];
    //bloop for debugging
    bloop = [aDecoder decodeIntForKey:@"bloop"];
    
    //persMat
    fx = [aDecoder decodeDoubleForKey:@"fx"];
    fy = [aDecoder decodeDoubleForKey:@"fy"];
    cx = [aDecoder decodeDoubleForKey:@"cx"];
    cy = [aDecoder decodeDoubleForKey:@"cy"];

    //distCoef
    d0 = [aDecoder decodeDoubleForKey:@"d0"];
    d1 = [aDecoder decodeDoubleForKey:@"d1"];
    d2 = [aDecoder decodeDoubleForKey:@"d2"];
    d3 = [aDecoder decodeDoubleForKey:@"d3"];
    
    [self createPerspectiveMatrix];
    [self createCameraMatrix];
    [self createDistMatrix];
    return self;
}

-(OpenGLWrapper *) initializeOpenGL {
    OpenGLWrapper *opengl = [[OpenGLWrapper alloc] init];
    [opengl initOpenGL:(void*)self];
    return opengl;
}
@end
