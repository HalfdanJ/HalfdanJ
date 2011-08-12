#pragma once
#import "BlobTracker2d.h"
#include "Plugin.h"
#import "Kinect.h"
#import "Keystoner.h"
#include "ofxShader.h"
#include "ofxFBOTexture.h"

#define BUFFER_SIZE 500

@interface Shadows : ofPlugin {
    BlobTrackerInstance2d * tracker;
    ofxCvGrayscaleImage * trackerImageRef;
    KinectInstance * kinect;
    KeystoneSurface * surface;
    
    ofxCvGrayscaleImage * buffer[BUFFER_SIZE];
    
    ofxCvGrayscaleImage * grayOutputImage;
    ofxCvGrayscaleImage * grayOutputImageTemp;
  
    ofxCvColorImage * lightImage;
        ofImage * lightFlashImage;
    ofxCvColorImage * output;;
    


    int bufferIndex;
    int bufferFill;
    
    ofxShader * shader;
    ofxFBOTexture * fbo1;
    ofImage * rampImg;
    
}

-(int) getCurrentBufferIndex;
@end
