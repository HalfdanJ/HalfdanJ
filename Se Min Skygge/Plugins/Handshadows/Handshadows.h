//
//  Handshadows
//  SeMinSkygge
//  
//  ofxCocoaPlugins plugin
//  Created by Se Min Skygge on 20/08/11.
//

#pragma once

#include "Plugin.h"
#include "Filter.h"
#include "Kinect.h"


#define NUM_BOXES 3

struct Box {
    Filter sides[4];
};

@interface Handshadows : ofPlugin{
    vector<Box> boxes;
    KinectInstance * kinect;

}

@end
