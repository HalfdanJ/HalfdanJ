//
//  Kalibrering
//  SeMinSkygge
//  
//  ofxCocoaPlugins plugin
//  Created by Jonas Jongejan on 9/8/11.
//

#pragma once

#include "Plugin.h"
#import "KinectCalibrator.h"



@interface Kalibrering : ofPlugin{
    NSMutableArray * calibrators;
    
    KinectInstance * kinect1;
    KinectInstance * kinect2;
    ofxOpenNIContext * context;
    
    ofxImageGenerator * image1;
    ofxImageGenerator * image2;
    
    bool firstRun;
}

@end
