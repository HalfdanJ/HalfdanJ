#pragma once

#include "Plugin.h"
#import "RenderObject.h"
#import "ofxFBOTexture.h"
#import "ofxShader.h"
#import "ofxVectorMath.h"
#import "Midi.h"

enum UpdateFlags {
    USE_ASSET_TEXTURE = 1,
    USE_BORDERED_FBO = 2,
    USE_CIIMAGE = 4,
    FILTER_CIIMAGE = 8,
    USE_CI_FBO = 16
    };

@class ObjectTreeViewController;

@interface RenderEngine : ofPlugin {
    Midi * midi;
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
    
    IBOutlet NSOutlineView *objectOutlineView;
    ObjectTreeViewController * treeController;
    
    float aspect;
    
    RenderObject * selectedObject;
}

@property (retain) NSMutableArray * objectsArray;
@property (assign) IBOutlet NSTreeController *objectTreeController;
@property (retain) NSString * assetDir;
@property (readwrite) ofxShader * blurShader;
@property (readonly)  CIContext *ciContext;
@property (readonly) ObjectTreeViewController * treeController;
@property (readonly) float aspect;
@property (readonly) Midi * midi;


- (IBAction)addObject:(id)sender;
- (IBAction)removeObject:(id)sender;
- (IBAction)setAssset:(id)sender;
- (IBAction)resetCam:(id)sender;

- (NSArray*) allObjects;
- (NSArray*) allObjectsOrderedByDepth;
- (NSArray*) rootObjectsOrdredByDepth;

- (RenderObject*) selectedObject;

-(void) renderFbo;

- (int) updateFlags;
@end
