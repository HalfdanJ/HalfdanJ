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
#import <QTKit/QTKit.h>

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
    QTMovie * videoAsset;
    
    GLuint assetTexture;
    CVOpenGLTextureRef  currentVideoFrame;
    QTVisualContextRef qtContext;    

    
    NSSize videoSize;


    float posX;
    float posY;
    float posZ;
    float depth;
    
    float scale;
    float rotationZ;
    float opacity;
    
    BOOL maskOnBack;
    BOOL autoFill;
    BOOL blendmodeAdd;
    BOOL visible;
    BOOL play;
    BOOL loop;

    int chapterFrom;
    int chapterTo;
    int objId;
    
    int stackMode;
    
    int sendMidiChapter;
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
    
    NSString * chapterOverview;
    
    
    float depthBlurAmount;
    
    RenderObjectType objectType;
    
    bool firstFrameAfterPlay;
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
@property (readwrite) float depth;
@property (readwrite) float scale;
@property (readwrite) float rotationZ;
@property (readwrite) float depthBlurAmount;
@property (readwrite) float opacity;
@property (readwrite) BOOL maskOnBack;
@property (readwrite) BOOL autoFill;
@property (readonly) BOOL isLeaf;
@property (readwrite) BOOL visible;
@property (readwrite) BOOL play;
@property (readwrite) BOOL loop;

@property (readwrite) int chapterFrom;
@property (readwrite) int chapterTo;
@property (readwrite) int objId;
@property (readwrite) int stackMode;

@property (readwrite)  NSString * chapterOverview;

@property (readwrite) BOOL blendmodeAdd;

-(void) loadAsset;

-(void) drawTexture:(GLuint)tex size:(NSRect)size;

-(void) drawWithAlpha:(float)alpha  front:(BOOL)front;
-(void) drawControlsWithColor:(NSColor*)color;
-(void) drawMaskWithAlpha:(float)alpha;

-(void) update:(NSDictionary *)drawingInformation;

//-(void) setupAssetOpengl;

-(BOOL) maskBack;
-(float) backAlpha;
-(float) frontAlpha;

-(float) aspect;

-(int) pixelsWide;
-(int) pixelsHigh;

-(float) absolutePosZ;
-(float) absolutePosZBack;
-(BOOL) absoluteVisible;

-(void) addSubObject:(RenderObject*)obj;
-(void) removeSubObject:(RenderObject*)obj;

- (BOOL)isImageFile:(NSString*)filePath;
@end
