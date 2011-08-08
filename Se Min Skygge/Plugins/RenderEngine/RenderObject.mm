//
//  RenderObject.m
//  SeMinSkygge
//
//  Created by Jonas Jongejan on 26/04/11.
//  Copyright 2011 HalfdanJ. All rights reserved.
//

#import "RenderObject.h"
#import "RenderEngine.h"


//#include "GLee.h"
//#include <OpenGL/glu.h>
//#include "ofConstants.h"

const int fboBorder = 20;

@implementation NSBitmapImageRep (OpenGLTexturing)

- (void)uploadAsOpenGLTexture:(GLuint)openGLName {
    GLsizei width  = [self pixelsWide];
    GLsizei height = [self pixelsHigh];
    NSBitmapImageRep *bitmapWhoseFormatIKnow = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height
                                                                                    bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
                                                                                   colorSpaceName:NSCalibratedRGBColorSpace bitmapFormat:0 bytesPerRow:width*4
                                                                                     bitsPerPixel:32];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapWhoseFormatIKnow]];
    [self drawInRect:NSMakeRect(0, 0, width, height)];
    [NSGraphicsContext restoreGraphicsState];
    unsigned char *bitmapData = [bitmapWhoseFormatIKnow bitmapData];
    
    /*    glPushClientAttrib( GL_CLIENT_PIXEL_STORE_BIT );											// be nice to anyone else who might use pixelStore
     // Set memory alignment parameters for unpacking the bitmap.
     glPixelStorei( GL_UNPACK_ALIGNMENT, 1 );
     glPixelStorei(GL_UNPACK_ROW_LENGTH, width);    
     glPopClientAttrib();
     */
    // Specify the texture's properties.
    glBindTexture( GL_TEXTURE_RECTANGLE_EXT, openGLName );
    glTexParameteri( GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_REPEAT );
    glTexParameteri( GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_REPEAT );
    glTexParameteri( GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
    glTexParameteri( GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
    
    // Upload the texture bitmap.  
    GLenum format =  GL_RGBA;
    GLenum internalFormat = GL_RGBA;
    glTexImage2D( GL_TEXTURE_RECTANGLE_EXT, 0, internalFormat, width, height, 0, format, GL_UNSIGNED_BYTE, bitmapData );
}

@end



//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------


@implementation RenderObject
@synthesize engine, name, subObjects, parent, assetString, assetInfo;
@synthesize posX, posY, posZ, scale,rotationZ,depthBlurAmount, opacity, maskOnBack, autoFill, blendmodeAdd, visible, play, chapterTo, chapterFrom, objId, loop, stackMode, depth;
- (id)init
{
    self = [super init];
    if (self) {
        [self addObserver:self forKeyPath:@"assetString" options:0 context:@"loadAsset"];
        
        subObjects = [NSMutableArray array];
        
        depthBlurFilter = [[CIFilter filterWithName:@"CIGaussianBlur"] retain];
        [depthBlurFilter setDefaults];
        
        resizeFilter = [[CIFilter filterWithName:@"CILanczosScaleTransform"] retain];
        [resizeFilter setDefaults];        
        [resizeFilter setValue:[NSNumber numberWithFloat:0.2] forKey:@"inputScale"];
        
        depthBlurAmount = -1;
        opacity = 1.0;
        scale = 1.0;
        visible = YES;
        play = YES;
        sendMidiChapter = -1;
        
        chapterFrom = 0;
        chapterTo = 127;
    }
    
    return self;
}

//------------------------------------------------------------------------------------------------------------------------


- (void)dealloc
{
    [super dealloc];
}

//------------------------------------------------------------------------------------------------------------------------


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if([(NSString*)context isEqualToString:@"loadAsset"]){
        if(engine != nil)
            [self loadAsset];
    }
    if([(NSString*)context isEqualToString:@"changedTexture"]){
        //changedFlag = YES;
        borderedFBOOutdated = YES;
        ciImageOutdated = YES;
        
    }    
}

//------------------------------------------------------------------------------------------------------------------------


-(void) transform{
    if(parent)
        [parent transform];
    
    float depthScale = [[[engine properties] objectForKey:@"camDepthScale"] floatValue] / 100.0;
    
    // if(!autoFill){
    float _scale = 1.0/(1+posZ * -0.3*depthScale);
    
    glTranslatef(posX, posY, 0);
    glTranslated([self aspect]*0.5, 0.5, 0);
    glScaled(_scale*scale, _scale*scale,_scale*scale);
    glRotated(rotationZ, 0,0,1);
    glTranslated(-[self aspect]*0.5, -0.5, 0);
    /*} else {
     
     float _scale = (1+posZ * -0.3*depthScale);
     
     glTranslatef(0, 0.5, -posZ);
     glScaled(_scale, _scale,_scale);
     // glRotated(rotationZ, 0,0,1);
     // glTranslated(-0.5, -0.5, 0);
     
     }*/
}

//------------------------------------------------------------------------------------------------------------------------


-(void) drawObject{
    
    int flags = [engine updateFlags];

    
    if(flags & USE_BORDERED_FBO){
        glScaled(1.0/([self pixelsWide]+2*fboBorder),1.0/([self pixelsHigh]+2*fboBorder),1); 
        glTranslated(-fboBorder, -fboBorder, 0);
        glScaled(([self pixelsWide]+4*fboBorder),([self pixelsHigh]+4*fboBorder),1);
    }
    
    if(flags & USE_CI_FBO){
        if(flags & USE_BORDERED_FBO){
            [self drawTexture:fbo->texData.textureID size:NSMakeRect(0,0,[self pixelsWide]+2*fboBorder, [self pixelsHigh]+2*fboBorder)];        
        } else {
            if(fbo){
                CGRect rect = filteredRect;
                
                glScaled(1.0/([self pixelsWide]),1.0/([self pixelsHigh]),1); 
                glTranslated(rect.origin.x, rect.origin.y,0);
                glScaled(rect.size.width, rect.size.height, 1);
                
                [self drawTexture:fbo->texData.textureID size:NSMakeRect(0,0,rect.size.width, rect.size.height)];                    
            }
        }
    } else if(flags & USE_CIIMAGE){
        glScaled(1.0/[ciImage extent].size.width, 1.0/[ciImage extent].size.height, 1);     
        [[engine ciContext] drawImage:outputImage 
                              atPoint:CGPointMake(0,0) // use integer coordinates to avoid interpolation
                             fromRect:[outputImage extent]];
    }
    else if(flags & USE_BORDERED_FBO){   
        [self drawTexture:borderFbo->texData.textureID size:NSMakeRect(0,0,[self pixelsWide]+2*fboBorder, [self pixelsHigh]+2*fboBorder)];        
    } else if(flags & USE_ASSET_TEXTURE){
        [self drawTexture:assetTexture size:NSMakeRect(0,0,[self pixelsWide], [self pixelsHigh])];
    } else {
        ofSetColor(200,255,255,200);
        ofRect(0,0,1,1);
    }
    
    
    //        fbo->draw(0,0,[self aspect],1);    
}

//------------------------------------------------------------------------------------------------------------------------


-(void)drawWithAlpha:(float)alpha front:(BOOL)front{
    ofEnableAlphaBlending();
    glColor4f(255,255,255,(float)alpha*[self opacity]);   
    glPushMatrix();{
        [self transform];        
        glScaled([self aspect],1,1);
        
        if(stackMode > 0){
            switch (stackMode) {
                case 1: //Front + back
                    if(front)
                        [self drawTexture:assetTexture size:NSMakeRect(0,0,[self pixelsWide], [self pixelsHigh])]; 
                    else
                        [self drawTexture:assetTexture size:NSMakeRect(0,[self pixelsHigh],[self pixelsWide], [self pixelsHigh])]; 
                    break;
                case 2: //Front + back + alpha
                
                    if(front){
                        glBlendFuncSeparate(GL_ZERO,GL_SRC_COLOR, GL_SRC_COLOR,GL_ZERO);        
                    
                        [self drawTexture:assetTexture size:NSMakeRect(0,2*[self pixelsHigh],[self pixelsWide], [self pixelsHigh])];
                        glBlendFuncSeparate(GL_DST_ALPHA,GL_DST_COLOR, GL_SRC_ALPHA,GL_DST_ALPHA);        

                        [self drawTexture:assetTexture size:NSMakeRect(0,0,[self pixelsWide], [self pixelsHigh])]; 
                    }else{
//                        glBlendFunc(GL_SRC_COLOR, GL_ONE);
                        glBlendFuncSeparate(GL_ZERO, GL_ONE, GL_SRC_COLOR,GL_ZERO);        

                        [self drawTexture:assetTexture size:NSMakeRect(0,2*[self pixelsHigh],[self pixelsWide], [self pixelsHigh])];

                        glBlendFuncSeparate(GL_ONE,GL_ONE, GL_DST_ALPHA, GL_ZERO);        

                        [self drawTexture:assetTexture size:NSMakeRect(0,[self pixelsHigh],[self pixelsWide], [self pixelsHigh])]; 
                        ofEnableAlphaBlending();
                    }
                    break;

                case 3: //Front + back + frontalpha
                    
                    if(front){
                        glBlendFuncSeparate(GL_ZERO,GL_SRC_COLOR, GL_SRC_COLOR,GL_ZERO);        
                        
                        [self drawTexture:assetTexture size:NSMakeRect(0,2*[self pixelsHigh],[self pixelsWide], [self pixelsHigh])];
                        glBlendFuncSeparate(GL_DST_ALPHA,GL_DST_COLOR, GL_SRC_ALPHA,GL_DST_ALPHA);        
                    
                        [self drawTexture:assetTexture size:NSMakeRect(0,0,[self pixelsWide], [self pixelsHigh])]; 
                    } else {
                        [self drawTexture:assetTexture size:NSMakeRect(0,[self pixelsHigh],[self pixelsWide], [self pixelsHigh])]; 
                    }
                    break;
                default:
                    break;
            }
        } else {
            [self drawObject];            
        }    
        
    }glPopMatrix();
}

//------------------------------------------------------------------------------------------------------------------------


-(void) drawMaskWithAlpha:(float)alpha{
    ofEnableAlphaBlending();
    glColor4f(255,255,255,(float)alpha*[self opacity]);   
    glPushMatrix();{
        [self transform];        
        glScaled([self aspect],1,1);
        
        if(stackMode > 0){
            switch (stackMode) {
                case 1: //Front + back
                    break;
                case 2: //Front + back + alpha
                        glBlendFuncSeparate(GL_ZERO,GL_SRC_COLOR, GL_SRC_COLOR,GL_ZERO);        
                        
                        [self drawTexture:assetTexture size:NSMakeRect(0,2*[self pixelsHigh],[self pixelsWide], [self pixelsHigh])];
/*                        glBlendFuncSeparate(GL_DST_ALPHA,GL_DST_COLOR, GL_SRC_ALPHA,GL_DST_ALPHA);        
                        
                        [self drawTexture:assetTexture size:NSMakeRect(0,0,[self pixelsWide], [self pixelsHigh])]; */

                    break;
                    
                case 3: //Front + back + frontalpha
                    
                        glBlendFuncSeparate(GL_ZERO,GL_SRC_COLOR, GL_SRC_COLOR,GL_ZERO);        
                        
                        [self drawTexture:assetTexture size:NSMakeRect(0,2*[self pixelsHigh],[self pixelsWide], [self pixelsHigh])];
                     /*   glBlendFuncSeparate(GL_DST_ALPHA,GL_DST_COLOR, GL_SRC_ALPHA,GL_DST_ALPHA);        
                        
                        [self drawTexture:assetTexture size:NSMakeRect(0,0,[self pixelsWide], [self pixelsHigh])]; */
                    break;
                default:
                    break;
            }
        }    
        
    }glPopMatrix();
 }

//------------------------------------------------------------------------------------------------------------------------


-(void) drawControlsWithColor:(NSColor*)color{
    glPushMatrix();{
        [self transform];  
        {
            glColor4f([color redComponent]*255.0, [color greenComponent]*255.0, [color blueComponent]*255.0, [color alphaComponent]*0.2);        
            glBegin(GL_QUADS);
            glVertex3f(0,0,0);
            glVertex3f([self aspect],0,0);
            glVertex3f([self aspect],1,0);
            glVertex3f(0,1,0);
            glVertex3f(0,0,0);
            glEnd();   
        }
        
        {
            glColor4f(255,255,255,[color alphaComponent]*opacity);
            glPushMatrix();
            glScaled([self aspect],1,1);
            //  [self drawImageAsset];
            if([engine updateFlags] & USE_ASSET_TEXTURE){
                [self drawTexture:assetTexture size:NSMakeRect(0,0,[self pixelsWide], [self pixelsHigh])];
            }
            glPopMatrix();
        }
        
        {
            glColor4f([color redComponent]*255.0, [color greenComponent]*255.0, [color blueComponent]*255.0, [color alphaComponent]*0.2);        
            glBegin(GL_QUADS);
            glVertex3f(0,0,0);
            glVertex3f([self aspect],0,0);
            glVertex3f([self aspect],1,0);
            glVertex3f(0,1,0);
            glVertex3f(0,0,0);
            glEnd();   
        }
        
        
        {        
            glColor4f([color redComponent]*255.0, [color greenComponent]*255.0, [color blueComponent]*255.0, [color alphaComponent]*255.0);        
            glBegin(GL_LINE_STRIP);
            glVertex3f(0,0,0);
            glVertex3f([self aspect],0,0);
            glVertex3f([self aspect],1,0);
            glVertex3f(0,1,0);
            glVertex3f(0,0,0);
            glEnd();        
        }    
        
    }glPopMatrix();
}

//------------------------------------------------------------------------------------------------------------------------


-(void) drawTexture:(GLuint)tex size:(NSRect)size{
    glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE );
    glEnable( GL_TEXTURE_RECTANGLE_EXT );
    glBindTexture( GL_TEXTURE_RECTANGLE_EXT, tex );    
    glBegin(GL_QUADS);
    glTexCoord2f(size.origin.x, size.origin.y); glVertex3f(0,0,0);
    glTexCoord2f(size.origin.x+size.size.width, size.origin.y); glVertex3f(1,0,0);
    glTexCoord2f(size.origin.x+size.size.width, size.origin.y+size.size.height);glVertex3f(1,1,0);
    glTexCoord2f(size.origin.x, size.origin.y+size.size.height); glVertex3f(0,1,0);
    glEnd();    
    glDisable(GL_TEXTURE_RECTANGLE_EXT);         
}

////------------------------------------------------------------------------------------------------------------------------
//
//
//-(void) allocateFBO{
//    NSLog(@"Allocate FBO");
//    if(borderFbo)
//        delete borderFbo;
//    borderFbo = new ofxFBOTexture();
//    borderFbo->allocate([self pixelsWide]+2*fboBorder, [self pixelsHigh]+2*fboBorder,GL_RGBA, 0);
//}

//------------------------------------------------------------------------------------------------------------------------



-(GLuint) uploadAssetTexture{
    //  NSLog(@"Upload asset %@",self);
    GLuint texture = 0;
    if(objectType == IMAGE){
        NSBitmapImageRep * rep = [[imageAsset representations] lastObject];
        glGenTextures( 1, &texture );            
        [rep uploadAsOpenGLTexture:texture];  
    } else if(objectType == VIDEO){
        texture = CVOpenGLTextureGetName(currentVideoFrame);
    }
    //  [self allocateFBO];
    
    return texture;
}

//------------------------------------------------------------------------------------------------------------------------


//-(GLuint) createBorderedFBOFromTexture:(GLuint)tex{
//    NSLog(@"Create bordered fbo");
//    if(borderFbo == nil){
//        [self allocateFBO];
//    }
//    
//    int w = [self pixelsWide]+2*fboBorder;
//    int h = [self pixelsHigh]+2*fboBorder;        
//    float screenFov = 60;    
//    float eyeX 		= (float)w / 2.0;
//    float eyeY 		= (float)h / 2.0;
//    float halfFov 	= PI * screenFov / 360.0;
//    float theTan 	= tanf(halfFov);
//    float dist 		= eyeY / theTan;
//    float nearDist 	= dist / 10.0;	// near / far clip plane
//    float farDist 	= dist * 10.0;
//    float as 			= (float)w/(float)h;  
//    borderFbo->clear(0,0,0,0);
//    borderFbo->swapIn();{
//        glEnable(GL_BLEND);
//        glBlendFunc(GL_ONE, GL_ONE);
//        
//        glPushMatrix();
//        glViewport(0, 0, w, h);    
//        glMatrixMode(GL_PROJECTION);
//        glLoadIdentity();
//        gluPerspective(screenFov, as, nearDist, farDist);        
//        glMatrixMode(GL_MODELVIEW);
//        glLoadIdentity();
//        gluLookAt(eyeX, eyeY, dist, eyeX, eyeY, 0.0, 0.0, 1.0, 0.0);        
//        glTranslated(fboBorder, fboBorder, 0);
//        glScaled([self pixelsWide],[self pixelsHigh],1);            
//        ofSetColor(255,255,255);
//        
//        if(tex!= 0){
//            [self drawTexture:tex size:NSMakeSize([self pixelsWide], [self pixelsHigh])];
//        } else {
//            ofSetColor(200,255,255,200);
//            ofRect(0,0,1,1);
//        }
//        glPopMatrix();
//    }borderFbo->swapOut();        
//    ofEnableAlphaBlending();
//    return borderFbo->texData.textureID;
//}

//------------------------------------------------------------------------------------------------------------------------


-(CIImage*) createCIImageFromTexture:(GLint)tex size:(NSSize)size{
    NSLog(@"Create CI Image");
    CIImage * image = [CIImage imageWithTexture:tex size:CGSizeMake(size.width, size.height) flipped:NO colorSpace:CGColorSpaceCreateDeviceRGB()];
    //  NSURL * url = [[NSURL alloc] initFileURLWithPath:[NSString stringWithFormat:@"%@%@", [engine assetDir],[self assetString]] isDirectory:NO];
    //    CIImage * image = [CIImage imageWithContentsOfURL:url];
    return image;
}

//------------------------------------------------------------------------------------------------------------------------


-(CIImage*) filterCIImage:(CIImage*)inputImage{
    //   [resizeFilter setValue:inputImage forKey:@"inputImage"];
    // [depthBlurFilter setValue:[resizeFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
    [depthBlurFilter setValue:inputImage forKey:@"inputImage"];
    CIImage * _outputImage = [depthBlurFilter valueForKey:@"outputImage"];
    return _outputImage;
}

//------------------------------------------------------------------------------------------------------------------------

-(GLuint) createFBOFromCIImage:(CIImage*)image{
    NSLog(@"Create FBO from CIImage");
    /*if(fbo == nil){
     [self allocateFBO];
     }*/
    
    if(fbo)
        delete fbo;
    
    
    int w = [image extent].size.width;
    int h = [image extent].size.height;
    
    fbo = new ofxFBOTexture();    
    fbo->allocate(w, h);
    
    
    float screenFov = 60;    
    float eyeX 		= (float)w / 2.0;
    float eyeY 		= (float)h / 2.0;
    float halfFov 	= PI * screenFov / 360.0;
    float theTan 	= tanf(halfFov);
    float dist 		= eyeY / theTan;
    float nearDist 	= dist / 10.0;	// near / far clip plane
    float farDist 	= dist * 10.0;
    float as 			= (float)w/(float)h;  
    
    fbo->clear(0,0,0,0);
    fbo->swapIn();{
        glBlendFunc(GL_ONE  , GL_ONE);            
        
        glPushMatrix();
        glViewport(0, 0, w, h);    
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        gluPerspective(screenFov, as, nearDist, farDist);        
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        gluLookAt(eyeX, eyeY, dist, eyeX, eyeY, 0.0, 0.0, 1.0, 0.0);        
        ofSetColor(255,255,255,255);
        
        filteredRect = (CGRect) [image extent];
        [[engine ciContext] drawImage:image 
                              atPoint:CGPointMake(0,0) // use integer coordinates to avoid interpolation
                             fromRect:[image extent]];
        
        glPopMatrix();
    }fbo->swapOut();
    ofEnableAlphaBlending();
    
    return fbo->texData.textureID;
}

//------------------------------------------------------------------------------------------------------------------------


-(void)update:(NSDictionary *)drawingInformation{		
    if(visible){
        int flags = [engine updateFlags];
        NSSize size;
        
        GLuint texture = 0;
        
        if(objectType == VIDEO){
            if(play && [videoAsset currentTime].timeValue >= [videoAsset duration].timeValue-0.05*[videoAsset duration].timeScale){
                //Videoen er nået til ende
                if(!loop){
                    play = NO;
                }
            } else if([videoAsset hasChapters] && play){
                int currentChapter = [videoAsset chapterIndexForTime:QTTimeIncrement([videoAsset currentTime],QTMakeTime(1, 30))];
                int numberChapters = [videoAsset chapterCount];
                int selectedChapter = chapterTo;
                if(currentChapter == numberChapters)
                    currentChapter --;
                
                
                if(currentChapter >= selectedChapter){
                    dispatch_async(dispatch_get_main_queue(), ^{     
                        if(!loop){
                            if(selectedChapter + 1 < numberChapters){					
                                [videoAsset setCurrentTime:QTTimeDecrement([videoAsset startTimeOfChapter:selectedChapter],QTMakeTime(2, 30))];
                            }                        
                            play = NO;
                        } else {
                            [videoAsset setCurrentTime:QTTimeDecrement([videoAsset startTimeOfChapter:chapterFrom],QTMakeTime(0, 30))];
                        }
                        //  NSLog(@"End of chapter.");
                    });
                } else {
                    
                    if(currentChapter != sendMidiChapter){
                        sendMidiChapter = currentChapter;
                        [[engine midi] sendValue:currentChapter forNote:objId onChannel:1];
                    }
                    play = YES;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                if([engine isEnabled] && visible && [videoAsset rate] == 0 && play){
                    [videoAsset setRate:1.0];
                }
                if((![engine isEnabled] || !visible) || ([videoAsset rate] != 0 && !play) ){
                    [videoAsset setRate:0.0];
                    //  NSLog(@"Stop video");
                }
            });
            
            
           QTVisualContextTask(qtContext);
            const CVTimeStamp * outputTime;
            [[drawingInformation objectForKey:@"outputTime"] getValue:&outputTime];	
            if (qtContext != NULL && QTVisualContextIsNewImageAvailable(qtContext, outputTime)) {
                if (NULL != currentVideoFrame) {
                    CVOpenGLTextureRelease(currentVideoFrame);
                    currentVideoFrame = NULL;
                }
                QTVisualContextCopyImageForTime(qtContext, NULL, outputTime, &currentVideoFrame);
                assetTextureOutdated = YES;
            }
        }
        
        
        
        if(flags & USE_ASSET_TEXTURE){
            if(assetTextureOutdated ){
                //Upload the texture to assetTexture
                assetTexture = [self uploadAssetTexture];
                assetTextureOutdated = NO;
                borderedFBOOutdated = YES;
                ciImageOutdated = YES;
            }
            texture = assetTexture;
            size = NSMakeSize([self pixelsWide], [self pixelsHigh]);
        }
        
        //   cout<<"Update texture "<<texture<<endl;
        
        /*if(flags & USE_BORDERED_FBO){
         if(borderedFBOOutdated){
         //Create a bordered FBO
         [self createBorderedFBOFromTexture:texture];
         ciImageOutdated = YES;
         borderedFBOOutdated = NO;
         }
         texture = borderFbo->texData.textureID;
         size = NSMakeSize([self pixelsWide]+2*fboBorder, [self pixelsHigh]+2*fboBorder);
         }*/
        
        
        
        if(flags & USE_CIIMAGE){
            if(ciImageOutdated && texture){  
                if(objectType == VIDEO){
                    ciImage = [CIImage imageWithCVImageBuffer:currentVideoFrame];
                } else {
                    ciImage = [self createCIImageFromTexture:texture size:size];
                }
                ciImageOutdated = NO;
                ciFilterOutdated = YES;
                ciFBOOutdated = YES;
            } else if(ciImageOutdated){
                ciImage = nil;
            }
        }
        CIImage * image = ciImage;
        
        if(flags & FILTER_CIIMAGE){
            if(ciFilterOutdated && image != nil){
                image = [self filterCIImage:ciImage];
                ciFilterOutdated = NO;
                ciFBOOutdated = YES;
            }
        }
        
        outputImage = image;
        
        
        if(flags & USE_CI_FBO){
            if(ciFBOOutdated){    
                texture = 0;
                if(outputImage){
                    texture = [self createFBOFromCIImage:outputImage];
                    ciFBOOutdated = NO;
                }
            }
        }
    }
    
}




-(void) loadAsset{
    [self willChangeValueForKey:@"imageRep"];
    [self willChangeValueForKey:@"assetLoaded"];    
    
    imageAsset = nil;
    
    
    [self setAssetInfo:@"No asset"];
    
    if(![[self assetString] isEqualToString:@""]){
        NSLog(@"Load from %@",[engine assetDir]);
        NSURL * url = [[NSURL alloc] initFileURLWithPath:[NSString stringWithFormat:@"%@%@", [engine assetDir],[self assetString]] isDirectory:NO];
        
        
        BOOL reachable = [url checkResourceIsReachableAndReturnError:nil];
        if(!reachable){
            NSLog(@"%@ not reachable", url);
            
        } else {
            NSLog(@"%@ reachable", url);  
            
            if([self isImageFile:[url relativePath]]){
                objectType = IMAGE;
            } else if([QTMovie canInitWithURL:url]){
                objectType = VIDEO;  
            } else {
                objectType = GENERIC;
            }
            
            if(objectType == IMAGE){
                NSLog(@"Load as image");
                imageAsset = [[NSImage alloc] initWithContentsOfURL:url];
                NSBitmapImageRep * rep = [[imageAsset representations] lastObject];
                
                NSMutableString * info = [NSMutableString string];
                [info appendString:@"Image asset\n"];
                [info appendFormat:@"Size: %ix%i",[rep pixelsWide],[rep pixelsHigh]];
                [self setAssetInfo:info];
            }
            if(objectType == VIDEO){
                NSLog(@"Load as video");
                NSError * error = [NSError alloc];			
                
                if (nil != videoAsset) [videoAsset release];                
                videoAsset = [[QTMovie alloc] initWithURL:url error:&error];
                if(error != nil){ 
                    NSLog(@"ERROR: Could not load movie: %@",error);
                }
                
                QTOpenGLTextureContextCreate(kCFAllocatorDefault,  CGLContextObj(CGLGetCurrentContext()), CGLGetPixelFormat(CGLGetCurrentContext()), NULL, &qtContext);
                
                SetMovieVisualContext([videoAsset quickTimeMovie], qtContext);
                
                
                [videoAsset setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieLoopsAttribute];
                //  [videoAsset setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
                
                NSArray* vtracks = [videoAsset tracksOfMediaType:QTMediaTypeVideo];
				QTTrack* track = [vtracks objectAtIndex:0];
				videoSize = [track apertureModeDimensionsForMode:QTMovieApertureModeClean];
				NSLog(@"Size: %@",NSStringFromSize(videoSize));				
                
                //Add start / end chapter
                
                /* NSArray * chapters = [NSArray arrayWithObjects:
                 [NSDictionary dictionaryWithObjectsAndKeys:
                 @"Start",QTMovieChapterName, 
                 [NSValue valueWithQTTime:QTMakeTime(0, 0)], QTMovieChapterStartTime,nil]
                 , nil];
                 [videoAsset addChapters:chapters withAttributes:[NSDictionary dictionary] error:&error];
                 */
            }
        }
        
    }
    
    //    changedFlag =YES;
    assetTextureOutdated = YES;
    borderedFBOOutdated = YES;
    
    [self didChangeValueForKey:@"assetLoaded"];
    [self didChangeValueForKey:@"imageRep"];   
}


-(NSImage *)imageRep{
    if(imageAsset != nil){
        return imageAsset;
    }
    return nil;
}

-(BOOL)assetLoaded{
    if(imageAsset != nil){
        return YES;
    }
    return NO;
}

-(BOOL)maskBack{
    return maskOnBack;
}

-(float)backAlpha{
    if(stackMode > 0)
        return 1;
    if([self absolutePosZ] <= 0)
        return 1;
    return 0;
}

-(float)frontAlpha{
    if(stackMode > 0)
        return 1;
    if([self absolutePosZ] <= 0)
        return 0;
    return 1;
}

-(int) pixelsWide{
    if(objectType == IMAGE){
        NSBitmapImageRep * rep = [[imageAsset representations] lastObject];
        return [rep pixelsWide];
    } else if(objectType == VIDEO){     
        return videoSize.width;
    } else {
        return 0;
    }
}

-(int) pixelsHigh{
    int ret = 0;
    if(objectType == IMAGE){
        NSBitmapImageRep * rep = [[imageAsset representations] lastObject];
        ret = [rep pixelsHigh];    
    } else if(objectType == VIDEO){
        ret = videoSize.height;
    } 
    if(stackMode == 1){
        ret /= 2;
    }
    if(stackMode >= 2){
        ret /= 3;
    }

    return ret;
}

-(float)aspect{
    /*  if(imageAsset != nil){
     return [imageAsset size].width / [imageAsset size].height;
     }    
     return 1;
     */
    float width = [self pixelsWide];
    float height = [self pixelsHigh];
    if(width != 0 && height != 0)
        return width / height;
    return 0;
}

-(float) absolutePosZ{
    if(parent)
        return [self posZ] + [parent absolutePosZ];
    return [self posZ];                
}
-(float) absolutePosZBack{
    return [self absolutePosZ] - depth;                
}

-(BOOL) absoluteVisible{
    if(parent)
        return [self visible] && [parent absoluteVisible];
    return [self visible];                
    
}


-(void)setAssetString:(NSString *)_assetString{
    if(_assetString != nil && engine){
        NSURL * url = [[NSURL alloc] initFileURLWithPath:_assetString isDirectory:NO];
        if([url baseURL] == nil){
            //Det er en path, den skal skrumpes
            NSRange range = [_assetString rangeOfString:[engine assetDir]];
            if(range.length > 0){
                //Den ligger i assets mappen
                _assetString = [_assetString stringByReplacingOccurrencesOfString:[engine assetDir] withString:@""];
            } else {
                NSLog(@"File not in assets folder");
            }
        }
    }
    assetString = _assetString;
}

-(void)setDepthBlurAmount:(float)_depthBlurAmount{
    if(fabs(depthBlurAmount - _depthBlurAmount) > 0.1){
        depthBlurAmount = _depthBlurAmount;
        NSLog(@"Update depth blur on %f %@",depthBlurAmount,self);
        
        [depthBlurFilter setValue:[NSNumber numberWithFloat:depthBlurAmount] forKey:@"inputRadius"];
        
        ciFBOOutdated = YES;
        ciFilterOutdated = YES;
    }
}


-(void)setEngine:(RenderEngine*)_e{
    engine = _e;
    
    [_e addObserver:self forKeyPath:@"assetDir" options:0 context:@"loadAsset"];
    
    [_e addObserver:self forKeyPath:@"properties.coreImageMode.value" options:0 context:@"changedTexture"];
    [_e addObserver:self forKeyPath:@"properties.assetTextureMode.value" options:0 context:@"changedTexture"];
    [_e addObserver:self forKeyPath:@"properties.borderedRendering.value" options:0 context:@"changedTexture"];
    
    //    if(assetString != nil)
    //        [self loadAsset];
}

-(BOOL)isLeaf{
    if([subObjects count] == 0)
        return YES;
    return NO;
}

-(void) addSubObject:(RenderObject*)obj{
    [self willChangeValueForKey:@"isLeaf"];
    [subObjects addObject:obj];
    [self didChangeValueForKey:@"isLeaf"];
}

-(void) removeSubObject:(RenderObject*)obj{
    [self willChangeValueForKey:@"isLeaf"];
    [subObjects removeObject:obj];
    [self didChangeValueForKey:@"isLeaf"];
    
}


-(id)initWithCoder:(NSCoder *)aDecoder{
    [self init];
    
    [self setName:[aDecoder decodeObjectForKey:@"name"]];
    [self setAssetString:[aDecoder decodeObjectForKey:@"assetString"]];
    [self setPosX:[aDecoder decodeFloatForKey:@"posX"]];
    [self setPosY:[aDecoder decodeFloatForKey:@"posY"]];
    [self setPosZ:[aDecoder decodeFloatForKey:@"posZ"]];    
    [self setDepth:[aDecoder decodeFloatForKey:@"depth"]];    
    [self setScale:[aDecoder decodeFloatForKey:@"scale"]];
    [self setRotationZ:[aDecoder decodeFloatForKey:@"rotationZ"]];
    [self setOpacity:[aDecoder decodeFloatForKey:@"opacity"]];
    [self setMaskOnBack:[aDecoder decodeBoolForKey:@"maskOnBack"]];
    [self setAutoFill:[aDecoder decodeBoolForKey:@"autoFill"]];
    [self setVisible:[aDecoder decodeBoolForKey:@"visible"]];
    [self setLoop:[aDecoder decodeBoolForKey:@"loop"]];
    [self setChapterFrom:[aDecoder decodeIntForKey:@"chapterFrom"]];
    [self setChapterTo:[aDecoder decodeIntForKey:@"chapterTo"]];
    [self setObjId:[aDecoder decodeIntForKey:@"objId"]];
    [self setStackMode:[aDecoder decodeIntForKey:@"stackMode"]];
    
    [self setBlendmodeAdd:[aDecoder decodeBoolForKey:@"blendmodeAdd"]];
    
    
    [self setSubObjects:[aDecoder decodeObjectForKey:@"subObjects"]];
    
    for(RenderObject * obj in subObjects){
        [obj setParent:self];
    }
    
    [self addObserver:self forKeyPath:@"assetString" options:0 context:@"loadAsset"];
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:name forKey:@"name"];
    [aCoder encodeObject:assetString forKey:@"assetString"];
    
    [aCoder encodeFloat:posX forKey:@"posX"];
    [aCoder encodeFloat:posY forKey:@"posY"];
    [aCoder encodeFloat:posZ forKey:@"posZ"];
    [aCoder encodeFloat:depth forKey:@"depth"];
    [aCoder encodeFloat:scale forKey:@"scale"];
    [aCoder encodeFloat:rotationZ forKey:@"rotationZ"];
    [aCoder encodeFloat:opacity forKey:@"opacity"];
    [aCoder encodeBool:maskOnBack forKey:@"maskOnBack"];
    [aCoder encodeBool:autoFill forKey:@"autoFill"];   
    [aCoder encodeBool:visible forKey:@"visible"]; 
    [aCoder encodeBool:loop forKey:@"loop"]; 
    [aCoder encodeInt:objId forKey:@"objId"]; 
    [aCoder encodeInt:stackMode forKey:@"stackMode"]; 
    
    [aCoder encodeInt:chapterFrom forKey:@"chapterFrom"]; 
    [aCoder encodeInt:chapterTo forKey:@"chapterTo"]; 
    
    [aCoder encodeBool:blendmodeAdd forKey:@"blendmodeAdd"];   
    
    [aCoder encodeObject:subObjects forKey:@"subObjects"];
}

-(NSString *)description{
    return [NSString stringWithFormat:@"RenderObject: %@",name];
}

- (BOOL)isImageFile:(NSString*)filePath
{
    BOOL isImageFile = NO;
    FSRef fileRef;
    Boolean isDirectory;
    
    if (FSPathMakeRef((const UInt8 *)[filePath fileSystemRepresentation], &fileRef, &isDirectory) == noErr)
    {
        // get the content type (UTI) of this file
        CFDictionaryRef values = NULL;
        CFStringRef attrs[1] = { kLSItemContentType };
        CFArrayRef attrNames = CFArrayCreate(NULL, (const void **)attrs, 1, NULL);
        
        if (LSCopyItemAttributes(&fileRef, kLSRolesViewer, attrNames, &values) == noErr)
        {
            // verify that this is a file that the Image I/O framework supports
            if (values != NULL)
            {
                CFTypeRef uti = CFDictionaryGetValue(values, kLSItemContentType);
                if (uti != NULL)
                {
                    CFArrayRef supportedTypes = CGImageSourceCopyTypeIdentifiers();
                    CFIndex i, typeCount = CFArrayGetCount(supportedTypes);
                    
                    for (i = 0; i < typeCount; i++)
                    {
                        CFStringRef supportedUTI = (CFStringRef) CFArrayGetValueAtIndex(supportedTypes, i);
                        
                        // make sure the supported UTI conforms only to "public.image" (this will skip PDF)
                        if (UTTypeConformsTo(supportedUTI, CFSTR("public.image")))
                        {
                            if (UTTypeConformsTo((CFStringRef)uti, (CFStringRef)supportedUTI))
                            {
                                isImageFile = YES;
                                break;
                            }
                        }
                    }
                    
                    CFRelease(supportedTypes);
                }
                
                CFRelease(values);
            }
        }
        
        CFRelease(attrNames);
    }
    
    return isImageFile;
}


-(void)setPlay:(BOOL)_play{
    play = _play;
    if(play){
        dispatch_async(dispatch_get_main_queue(), ^{
            if(videoAsset){
                if(chapterFrom != 0 && [videoAsset chapterCount] >= chapterFrom){
                    [videoAsset setCurrentTime:[videoAsset startTimeOfChapter:chapterFrom]];
                } else {
                    [videoAsset setCurrentTime:QTMakeTime(0, 0)];
                    
                }
                [videoAsset setRate:1.0];
                
            }
        });
    }      
    if(!play){
        dispatch_async(dispatch_get_main_queue(), ^{
            if(videoAsset){
                [videoAsset setRate:0.0];
            }
        });
    }
    
}

@end
