//
//  RenderObject.h
//  SeMinSkygge
//
//  Created by Jonas Jongejan on 26/04/11.
//  Copyright 2011 HalfdanJ. All rights reserved.
//

#include "Plugin.h"
#include "ofxFBOTexture.h"
#import "ofxShader.h"

@class RenderEngine;

@interface RenderObject : NSObject <NSCoding>{
    NSString * name;
    NSMutableArray * subObjects;
    
    
    RenderEngine * engine;
    
    NSString * assetString;
    NSString * assetInfo;
    
    NSImage * imageAsset;
    GLuint imageTexture;
    
    float posX;
    float posY;
    float posZ;
    
    float scale;
    float rotationZ;
    
    ofxFBOTexture * borderFbo;
    ofxFBOTexture * tempFbo;
    ofxFBOTexture * fbo;
    

}

@property (retain) NSString * name;
@property (retain) NSString * assetString;
@property (retain) NSMutableArray * subObjects;
@property (assign) RenderEngine * engine;

@property (readonly) NSImage * imageRep;
@property (readonly) BOOL assetLoaded;
@property (retain) NSString * assetInfo;

@property (readwrite) float posX;
@property (readwrite) float posY;
@property (readwrite) float posZ;
@property (readwrite) float scale;
@property (readwrite) float rotationZ;

-(void) loadAsset;

-(void) drawImageAsset;

-(void) drawWithAlpha:(float)alpha;
-(void) drawControlsWithColor:(NSColor*)color;
-(void) drawMaskWithAlpha:(float)alpha;
-(void) renderFbo;
-(void) drawFbo;

-(void) setupAssetOpengl;

-(BOOL) maskBack;
-(float) backAlpha;
-(float) frontAlpha;

-(float) aspect;

-(int) pixelsWide;
-(int) pixelsHigh;
@end
