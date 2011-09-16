//
//  KinectCalibrator.h
//  SeMinSkygge
//
//  Created by Jonas Jongejan on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kinect.h"

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
    int proj;

}
@property ofxImageGenerator * image;
@property int proj;

-(void)update:(NSDictionary *)drawingInformation;
-(void)controlDraw:(NSDictionary *)drawingInformation;
-(void)draw:(NSDictionary *)drawingInformation;

@end


@interface KinectCalibrator : NSObject{
    KinectInstance * kinect;
    
}
@property (readwrite, assign) KinectInstance * kinect;

@end
