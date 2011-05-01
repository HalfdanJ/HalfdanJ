#pragma once

#include "Plugin.h"
#import "RenderObject.h"
#import "ofxFBOTexture.h"
#import "ofxShader.h"

@interface RenderEngine : ofPlugin {
    NSMutableArray * objectsArray;
    NSTreeController *objectTreeController;
    
    NSString * assetDir;
    
    ofxFBOTexture *fboFront, *fboBack;
    
    ofxShader * blurShader;

}

@property (retain) NSMutableArray * objectsArray;
@property (assign) IBOutlet NSTreeController *objectTreeController;
@property (retain) NSString * assetDir;
@property (readwrite) ofxShader * blurShader;


- (IBAction)addObject:(id)sender;
- (IBAction)setAssset:(id)sender;

- (NSArray*) allObjects;
- (NSArray*) allObjectsOrderedByDepth;

- (RenderObject*) selectedObject;
@end
