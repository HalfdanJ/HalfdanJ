#pragma once

#include "Plugin.h"

#import "Keystoner.h"
#import "Kinect.h"
#include "Firefly.h"

@interface Fireflies : ofPlugin{
    KinectInstance * kinect;
    KeystoneSurface * surface;

    vector<Firefly> fireflies;
    
    int numFlies;
    
    ofxPerlin *noise;
    
    int frameNum;
}

@end
