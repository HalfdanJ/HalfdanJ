#pragma once

#include "Plugin.h"
#import "RenderObject.h"
#import "ofxFBOTexture.h"
#import "ofxShader.h"


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
    
    CIContext * ciContext;
    
    int pingpong;
    
    CFAbsoluteTime time;
}

@property (retain) NSMutableArray * objectsArray;
@property (assign) IBOutlet NSTreeController *objectTreeController;
@property (retain) NSString * assetDir;
@property (readwrite) ofxShader * blurShader;
@property (readonly)  CIContext *ciContext;


- (IBAction)addObject:(id)sender;
- (IBAction)removeObject:(id)sender;
- (IBAction)setAssset:(id)sender;

- (NSArray*) allObjects;
- (NSArray*) allObjectsOrderedByDepth;

- (RenderObject*) selectedObject;

- (int) updateFlags;
@end
