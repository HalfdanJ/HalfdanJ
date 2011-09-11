//
//  Kalibrering
//  SeMinSkygge
//  
//  ofxCocoaPlugins plugin
//  Created by Jonas Jongejan on 9/8/11.
//

#pragma once

#include "Plugin.h"
#import "Keystoner.h"
#import "Kinect.h"

@interface ProjectorAlignment : NSObject {
}

-(void)update:(NSDictionary *)drawingInformation;
-(void)draw:(NSDictionary *)drawingInformation;

@end






@interface ProjectorCalibrator : NSObject{
    KeystoneSurface * surface;
    KinectInstance * kinect;
    
    int corner;
    
    NSRect rect;
    bool widthHeightSwitcher;
} 

@property (readwrite, assign) KeystoneSurface * surface;
@property (readwrite, assign) KinectInstance * kinect;

-(void)update:(NSDictionary *)drawingInformation;
-(void)controlDraw:(NSDictionary *)drawingInformation;

@end
