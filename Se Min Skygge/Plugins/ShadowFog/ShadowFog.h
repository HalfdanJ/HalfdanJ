#pragma once

#include "Plugin.h"

#import "Keystoner.h"
#import "Kinect.h"


@interface ShadowFog : ofPlugin{
    ofxCvGrayscaleImage * trackerImageRef;
    KinectInstance * kinect;
    KeystoneSurface * surface;
    
    ofxCvGrayscaleImage * grayOutputImage;
    ofxCvGrayscaleImage * grayOutputImageTemp;
    ofxCvGrayscaleImage * grayOutputImageTemp2;
}

@end
