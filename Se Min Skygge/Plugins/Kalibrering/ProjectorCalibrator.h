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
#import "ofxOpenCv.h"



@interface ProjectorTest : NSObject {
}

-(void)update:(NSDictionary *)drawingInformation;
-(void)draw:(NSDictionary *)drawingInformation;

@end



@interface ProjectorAlignment : NSObject {
}

-(void)update:(NSDictionary *)drawingInformation;
-(void)draw:(NSDictionary *)drawingInformation;

@end






@interface ProjectorAutoCalibrator : NSObject{
    KeystoneSurface * surface;
    ofxImageGenerator * image;
    ofxCvColorImage * bg;
    ofxCvColorImage * diff;
    ofxCvColorImage * now;

    ofxPoint2f corners[4];
    int corner;
    int step;
    
    NSRect rect;
    bool widthHeightSwitcher;
    
    long timer;
    
    int bgNoise;
} 

@property (readwrite, assign) KeystoneSurface * surface;
@property (readwrite, assign) ofxImageGenerator * image;

-(void)update:(NSDictionary *)drawingInformation;
-(void)controlDraw:(NSDictionary *)drawingInformation;
-(void)draw:(NSDictionary *)drawingInformation;
-(void) go;
@end
