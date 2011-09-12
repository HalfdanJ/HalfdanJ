//
//  KinectCalibrator.h
//  SeMinSkygge
//
//  Created by Jonas Jongejan on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kinect.h"

@interface KinectAlignment : NSObject{
    ofTrueTypeFont * font;
    
    ofxImageGenerator * image;
    
}
@property ofxImageGenerator * image;

-(void)update:(NSDictionary *)drawingInformation;
-(void)controlDraw:(NSDictionary *)drawingInformation;
-(void)draw:(NSDictionary *)drawingInformation;

@end


@interface KinectCalibrator : NSObject{
    KinectInstance * kinect;
    
}
@property (readwrite, assign) KinectInstance * kinect;

@end
