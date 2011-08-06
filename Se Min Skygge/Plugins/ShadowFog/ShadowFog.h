#pragma once

#include "Plugin.h"

#import "Keystoner.h"
#import "Kinect.h"


@interface ShadowFog : ofPlugin{
    ofxCvGrayscaleImage * trackerImageRef;
    KinectInstance * kinect;
    KeystoneSurface * surface;
    
    ofxCvGrayscaleImage * grayOutputImage, * grayOutputImageFront;
    ofxCvGrayscaleImage * grayOutputImageTemp, * grayOutputImageFrontTemp;
    ofxCvGrayscaleImage * grayOutputImageTemp2;
}

@end
