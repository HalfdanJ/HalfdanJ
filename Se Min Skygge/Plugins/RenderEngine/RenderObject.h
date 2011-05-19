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

enum RenderObjectType {
    GENERIC = 0,
    IMAGE = 1,
    VIDEO = 2
    };

@class RenderEngine;

@interface RenderObject : NSObject <NSCoding>{
    NSString * name;
    NSMutableArray * subObjects;
    RenderObject * parent;
    
    
    RenderEngine * engine;
    
    NSString * assetString;
    NSString * assetInfo;
    
    NSImage * imageAsset;

    GLuint assetTexture;
    
    float posX;
    float posY;
    float posZ;
    
    float scale;
    float rotationZ;
    float opacity;
    
    BOOL maskOnBack;
    BOOL autoFill;
    
    ofxFBOTexture * borderFbo;
//    ofxFBOTexture * tempFbo;
    ofxFBOTexture * fbo;
    
    CIImage * ciImage;
    CIImage * outputImage;
    CGRect filteredRect;

    CIFilter * depthBlurFilter;
    CIFilter * resizeFilter;

    BOOL assetTextureOutdated;
    BOOL borderedFBOOutdated;
    BOOL ciImageOutdated;
    BOOL ciFilterOutdated;
    BOOL ciFBOOutdated;
    
    float depthBlurAmount;
    
    RenderObjectType objectType;
}

@property (retain) NSString * name;
@property (retain) NSString * assetString;
@property (retain) NSMutableArray * subObjects;
@property (retain) RenderObject * parent;
@property (assign) RenderEngine * engine;

@property (readonly) NSImage * imageRep;
@property (readonly) BOOL assetLoaded;
@property (retain) NSString * assetInfo;

@property (readwrite) float posX;
@property (readwrite) float posY;
@property (readwrite) float posZ;
@property (readwrite) float scale;
@property (readwrite) float rotationZ;
@property (readwrite) float depthBlurAmount;
@property (readwrite) float opacity;
@property (readwrite) BOOL maskOnBack;
@property (readwrite) BOOL autoFill;
@property (readonly) BOOL isLeaf;

-(void) loadAsset;

-(void) drawTexture:(GLuint)tex size:(NSSize)size;

-(void) drawWithAlpha:(float)alpha;
-(void) drawControlsWithColor:(NSColor*)color;
-(void) drawMaskWithAlpha:(float)alpha;

-(void) update;

-(void) setupAssetOpengl;

-(BOOL) maskBack;
-(float) backAlpha;
-(float) frontAlpha;

-(float) aspect;

-(int) pixelsWide;
-(int) pixelsHigh;

-(float) absolutePosZ;

-(void) addSubObject:(RenderObject*)obj;
-(void) removeSubObject:(RenderObject*)obj;

- (BOOL)isImageFile:(NSString*)filePath;
@end
