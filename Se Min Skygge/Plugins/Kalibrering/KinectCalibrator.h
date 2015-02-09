//
//  KinectCalibrator.h
//  SeMinSkygge
//
//  Created by Jonas Jongejan on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kinect.h"
#import "ofxOpenCv.h"

@interface KinectTest : NSObject{
    ofTrueTypeFont * font;    
    ofxImageGenerator * image1;    
    ofxImageGenerator * image2;    
    int proj;
}
@property ofxImageGenerator * image1;
@property ofxImageGenerator * image2;

@property int proj;

-(void)update:(NSDictionary *)drawingInformation;
-(void)controlDraw:(NSDictionary *)drawingInformation;
-(void)draw:(NSDictionary *)drawingInformation;

@end



@interface KinectAlignment : NSObject{
    ofTrueTypeFont * font;
    
    ofxImageGenerator * image;
    KinectInstance * kinect;
    int proj;
    BOOL depth;

}
@property ofxImageGenerator * image;
@property (readwrite, assign) KinectInstance * kinect;
@property int proj;
@property BOOL depth;

-(void)update:(NSDictionary *)drawingInformation;
-(void)controlDraw:(NSDictionary *)drawingInformation;
-(void)draw:(NSDictionary *)drawingInformation;

@end


@interface KinectCalibrator : NSObject{
    KinectInstance * kinect;
    ofxCvGrayscaleImage * bg;
    ofxCvGrayscaleImage * diff;
    ofxCvGrayscaleImage * now;
    
    ofxCvContourFinder * tracker;

    int corner;
    int step;
    
    long timer;

    int bgNoise;
    
    PluginProperty * threshold;
    PluginProperty * blur;
    int proj;
    
    ofxPoint2f p;
    
    bool personFound;
    bool pStable;
    
    BOOL depth;
    
    unsigned char depth_pixels[640*480];
    const XnDepthPixel depthBg[640*480];

}
@property (readwrite, assign) KinectInstance * kinect;
@property (readwrite, assign) PluginProperty * threshold;
@property (readwrite, assign) PluginProperty * blur;
@property int proj;
@property BOOL depth;

-(void) go;
-(void)update:(NSDictionary *)drawingInformation;
-(void)controlDraw:(NSDictionary *)drawingInformation;
-(void)draw:(NSDictionary *)drawingInformation;

@end
