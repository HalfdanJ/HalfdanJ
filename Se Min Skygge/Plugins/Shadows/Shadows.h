#pragma once
#import "BlobTracker2d.h"
#include "Plugin.h"
#import "Kinect.h"
#import "Keystoner.h"
#include "ofxShader.h"
#include "ofxFBOTexture.h"
#include "shaderBlur.h"

#define BUFFER_SIZE 500

struct keyframe {
    float time;
    float value;
};

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
    
    ofxCvGrayscaleImage * bgCache;


    int bufferIndex;
    int bufferFill;
    bool pingpong;
    
    ofxShader shader;
    ofxFBOTexture * motionblurFbo[2];
    shaderBlur * blur;
    shaderBlur * blurHist;
    ofImage rampImg;
    
    ofxFBOTexture * history[BUFFER_SIZE];
    long long historyTime[BUFFER_SIZE];
    
    NSString * timeline;
    
    vector<keyframe> keyframes;
}
@property (readwrite, assign) NSString * timeline;

-(int) getCurrentBufferIndex;
-(float) valueForTime:(float)time;
@end
