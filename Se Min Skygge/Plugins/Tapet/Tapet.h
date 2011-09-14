//
//  Tapet
//  SeMinSkygge
//  
//  ofxCocoaPlugins plugin
//  Created by Se Min Skygge on 31/08/11.
//

#pragma once

#include "Plugin.h"
#include "ofxShader.h"

@interface Tapet : ofPlugin{
    ofImage * tapetImage;
    ofImage * patImage;
    ofImage * maskImage;
    ofImage * maskImageInv;
    ofImage * maskImage2;
    ofImage * maskImageInv2;

    
    ofxShader shader;
    ofImage rampImg;

}

@end
