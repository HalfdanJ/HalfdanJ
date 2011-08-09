#pragma once

#include "Plugin.h"

#import "Keystoner.h"
#import "Kinect.h"
#include "Firefly.h"

@interface Fireflies : ofPlugin{
    KinectInstance * kinect;
    KeystoneSurface * surface;
    ofImage * img;

    vector<Firefly> fireflies;
    
    int numFlies;
    
    ofxPerlin *noise;
    
    int frameNum;
    
    float gravityForce;
    float perlinForce;
    float perlinGridsize;
    float perlinSpeed;
    float opacitySpeed;
    float opacityNoise;
    float wortexForce;
    float damping;

}

@end
