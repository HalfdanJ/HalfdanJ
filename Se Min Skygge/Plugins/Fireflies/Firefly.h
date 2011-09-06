#pragma once

#include "ofMain.h"
#include "ofxVectorMath.h"
#include "ofxNoise.h"

class Firefly {
public:
    Firefly();
    
    void update(float step, int frameNum,  ofxVec2f center);
    void draw(bool front);
    
    
    ofxVec3f pos;
    ofxVec3f a;
    ofxVec3f v;
    
    ofxPerlin *noise;
    ofImage * img;

    float opacity;
    
    int i;
    
    float * gravityForce;
    float * perlinForce;
    float * perlinGridsize;
    float * perlinSpeed;
    float * opacitySpeed;
    float * opacityNoise;
    float * wortexForce;
    float * damping;
};