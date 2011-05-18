#pragma once

#include "Plugin.h"
#import "RenderObject.h"
#import "ofxFBOTexture.h"
#import "ofxShader.h"
#import "ofxVectorMath.h"

enum UpdateFlags {
    USE_ASSET_TEXTURE = 1,
    USE_BORDERED_FBO = 2,
    USE_CIIMAGE = 4,
    FILTER_CIIMAGE = 8,
    USE_CI_FBO = 16
    };


@interface RenderEngine : ofPlugin {
    NSMutableArray * objectsArray;
    NSTreeController *objectTreeController;
    
    NSString * assetDir;
    
    ofxFBOTexture *fboFront[2], *fboBack[2];
    
    ofxShader * blurShader;
    ofxShader * colorCorrectShader;
    
    CIContext * ciContext;
    
    int pingpong;
  
    ofxVec3f camCoord;
    ofxVec3f eyeCoord;
    
    float mouseLastX,mouseLastY;
    IBOutlet NSButton *autoPanCheckbox;
    IBOutlet NSSlider *autoPanSpeed;
}

@property (retain) NSMutableArray * objectsArray;
@property (assign) IBOutlet NSTreeController *objectTreeController;
@property (retain) NSString * assetDir;
@property (readwrite) ofxShader * blurShader;
@property (readonly)  CIContext *ciContext;


- (IBAction)addObject:(id)sender;
- (IBAction)removeObject:(id)sender;
- (IBAction)setAssset:(id)sender;
- (IBAction)resetCam:(id)sender;

- (NSArray*) allObjects;
- (NSArray*) allObjectsOrderedByDepth;

- (RenderObject*) selectedObject;

-(void) renderFbo;

- (int) updateFlags;
@end
