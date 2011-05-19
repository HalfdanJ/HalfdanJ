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
    
    // Set memory alignment parameters for unpacking the bitmap.
    glPixelStorei( GL_UNPACK_ALIGNMENT, 1 );
    glPixelStorei(GL_UNPACK_ROW_LENGTH, width);
    
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
@synthesize posX, posY, posZ, scale,rotationZ,depthBlurAmount, opacity, maskOnBack, autoFill;
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
    
    if(!autoFill){
        glTranslatef(posX, posY, posZ);
        glScaled(scale, scale,scale);
        glRotated(rotationZ, 0,0,1);
        glTranslated(-[self aspect]*0.5, -0.5, 0);
    } else {
        float depthScale = [[[engine properties] objectForKey:@"camDepthScale"] floatValue] / 100.0;
        
        float _scale = (1+posZ * -0.3*depthScale);
        
        glTranslatef(0, 0.5, posZ);
        glScaled(_scale, _scale,_scale);
        glRotated(rotationZ, 0,0,1);
        glTranslated(-0.5, -0.5, 0);
        
    }
}

//------------------------------------------------------------------------------------------------------------------------


-(void) drawObject{
    int flags = [engine updateFlags];
    glScaled([self aspect],1,1);
    
    if(flags & USE_BORDERED_FBO){
        glScaled(1.0/([self pixelsWide]+2*fboBorder),1.0/([self pixelsHigh]+2*fboBorder),1); 
        glTranslated(-fboBorder, -fboBorder, 0);
        glScaled(([self pixelsWide]+4*fboBorder),([self pixelsHigh]+4*fboBorder),1);
    }
    
    if(flags & USE_CI_FBO){
        if(flags & USE_BORDERED_FBO){
            [self drawTexture:fbo->texData.textureID size:NSMakeSize([self pixelsWide]+2*fboBorder, [self pixelsHigh]+2*fboBorder)];        
        } else {
            if(fbo){
                CGRect rect = filteredRect;
                
                glScaled(1.0/([self pixelsWide]),1.0/([self pixelsHigh]),1); 
                glTranslated(rect.origin.x, rect.origin.y,0);
                glScaled(rect.size.width, rect.size.height, 1);
                
                [self drawTexture:fbo->texData.textureID size:NSMakeSize(rect.size.width, rect.size.height)];                    
            }
        }
    } else if(flags & USE_CIIMAGE){
        glScaled(1.0/[ciImage extent].size.width, 1.0/[ciImage extent].size.height, 1);     
        [[engine ciContext] drawImage:outputImage 
                              atPoint:CGPointMake(0,0) // use integer coordinates to avoid interpolation
                             fromRect:[outputImage extent]];
        
        //        [ciImage drawAtPoint:CGPointMake(0,0) fromRect:[ciImage extent] operation: NSCompositeClear   fraction:1.0];
        
    }
    else if(flags & USE_BORDERED_FBO){   
        [self drawTexture:borderFbo->texData.textureID size:NSMakeSize([self pixelsWide]+2*fboBorder, [self pixelsHigh]+2*fboBorder)];        
    } else if(flags & USE_ASSET_TEXTURE){
        [self drawTexture:assetTexture size:NSMakeSize([self pixelsWide], [self pixelsHigh])];
    } else {
        ofSetColor(200,255,255,200);
        ofRect(0,0,1,1);
    }
    
    
    //        fbo->draw(0,0,[self aspect],1);    
}

//------------------------------------------------------------------------------------------------------------------------


-(void)drawWithAlpha:(float)alpha{
    glColor4f(255,255,255,(float)alpha*opacity);    
    glPushMatrix();{
        [self transform];        
        [self drawObject];
        
    }glPopMatrix();
}

//------------------------------------------------------------------------------------------------------------------------


-(void) drawMaskWithAlpha:(float)alpha{
    /*   glColor4f(0,0,0,alpha*opacity);    
     glPushMatrix();{
     [self transform];        
     fbo->draw(0,0,[self aspect],1);
     
     }glPopMatrix();*/
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
                [self drawTexture:assetTexture size:NSMakeSize([self pixelsWide], [self pixelsHigh])];
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


-(void) drawTexture:(GLuint)tex size:(NSSize)size{
    glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE );
    glEnable( GL_TEXTURE_RECTANGLE_EXT );
    glBindTexture( GL_TEXTURE_RECTANGLE_EXT, tex );    
    glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex3f(0,0,0);
    glTexCoord2f(size.width, 0); glVertex3f(1,0,0);
    glTexCoord2f(size.width, size.height);glVertex3f(1,1,0);
    glTexCoord2f(0, size.height); glVertex3f(0,1,0);
    glEnd();    
    glDisable(GL_TEXTURE_RECTANGLE_EXT);         
}

//------------------------------------------------------------------------------------------------------------------------


-(void) allocateFBO{
    NSLog(@"Allocate FBO");
    if(borderFbo)
        delete borderFbo;
    borderFbo = new ofxFBOTexture();
    borderFbo->allocate([self pixelsWide]+2*fboBorder, [self pixelsHigh]+2*fboBorder,GL_RGBA, 0);
}

//------------------------------------------------------------------------------------------------------------------------



-(GLuint) uploadAssetTexture{
    NSLog(@"Upload asset %@",self);
    GLuint texture = 0;
    if(objectType == IMAGE){
        NSBitmapImageRep * rep = [[imageAsset representations] lastObject];
        glGenTextures( 1, &texture );            
        [rep uploadAsOpenGLTexture:texture];  
        [self allocateFBO];
    }    
    return texture;
}

//------------------------------------------------------------------------------------------------------------------------


-(GLuint) createBorderedFBOFromTexture:(GLuint)tex{
    NSLog(@"Create bordered fbo");
    if(borderFbo == nil){
        [self allocateFBO];
    }
    
    int w = [self pixelsWide]+2*fboBorder;
    int h = [self pixelsHigh]+2*fboBorder;        
    float screenFov = 60;    
    float eyeX 		= (float)w / 2.0;
    float eyeY 		= (float)h / 2.0;
    float halfFov 	= PI * screenFov / 360.0;
    float theTan 	= tanf(halfFov);
    float dist 		= eyeY / theTan;
    float nearDist 	= dist / 10.0;	// near / far clip plane
    float farDist 	= dist * 10.0;
    float as 			= (float)w/(float)h;  
    borderFbo->clear(0,0,0,0);
    borderFbo->swapIn();{
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE);
        
        glPushMatrix();
        glViewport(0, 0, w, h);    
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        gluPerspective(screenFov, as, nearDist, farDist);        
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        gluLookAt(eyeX, eyeY, dist, eyeX, eyeY, 0.0, 0.0, 1.0, 0.0);        
        glTranslated(fboBorder, fboBorder, 0);
        glScaled([self pixelsWide],[self pixelsHigh],1);            
        ofSetColor(255,255,255);
        
        if(tex!= 0){
            [self drawTexture:tex size:NSMakeSize([self pixelsWide], [self pixelsHigh])];
        } else {
            ofSetColor(200,255,255,200);
            ofRect(0,0,1,1);
        }
        glPopMatrix();
    }borderFbo->swapOut();        
    ofEnableAlphaBlending();
    return borderFbo->texData.textureID;
}

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


-(void)update{
    int flags = [engine updateFlags];
    NSSize size;
    
    GLuint texture = 0;
    
    if(flags & USE_ASSET_TEXTURE){
        if(assetTextureOutdated){
            //Upload the texture to assetTexture
            assetTexture = [self uploadAssetTexture];
            assetTextureOutdated = NO;
            borderedFBOOutdated = YES;
            ciImageOutdated = YES;
        }
        texture = assetTexture;
        size = NSMakeSize([self pixelsWide], [self pixelsHigh]);
    }
    
    
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
            ciImage = [self createCIImageFromTexture:texture size:size];
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




-(void) loadAsset{
    [self willChangeValueForKey:@"imageRep"];
    [self willChangeValueForKey:@"assetLoaded"];    
    
    imageAsset = nil;
    
    
    [self setAssetInfo:@"No asset"];
    
    if(![[self assetString] isEqualToString:@""]){
        
        NSURL * url = [[NSURL alloc] initFileURLWithPath:[NSString stringWithFormat:@"%@%@", [engine assetDir],[self assetString]] isDirectory:NO];
        
        
        BOOL reachable = [url checkResourceIsReachableAndReturnError:nil];
        if(!reachable){
            NSLog(@"%@ not reachable", url);
            
        } else {
            NSLog(@"%@ reachable", url);  
            
            if([self isImageFile:[url relativePath]]){
                objectType = IMAGE;
            } else {
                objectType = GENERIC;
            }
            
            if(objectType == IMAGE){
                imageAsset = [[NSImage alloc] initWithContentsOfURL:url];
                NSBitmapImageRep * rep = [[imageAsset representations] lastObject];
                
                NSMutableString * info = [NSMutableString string];
                [info appendString:@"Image asset\n"];
                [info appendFormat:@"Size: %ix%i",[rep pixelsWide],[rep pixelsHigh]];
                [self setAssetInfo:info];
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
    if([self absolutePosZ] <= 0)
        return 1;
    return 0;
}

-(float)frontAlpha{
    if([self absolutePosZ] <= 0)
        return 0;
    return 1;
}

-(int) pixelsWide{
    NSBitmapImageRep * rep = [[imageAsset representations] lastObject];
    return [rep pixelsWide];
}

-(int) pixelsHigh{
    NSBitmapImageRep * rep = [[imageAsset representations] lastObject];
    return [rep pixelsHigh];
}

-(float)aspect{
    if(imageAsset != nil){
        return [imageAsset size].width / [imageAsset size].height;
    }    
    return 1;
}

-(float) absolutePosZ{
    if(parent)
        return [self posZ] + [parent absolutePosZ];
    return [self posZ];                
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
    
    [self loadAsset];
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
    [self setScale:[aDecoder decodeFloatForKey:@"scale"]];
    [self setRotationZ:[aDecoder decodeFloatForKey:@"rotationZ"]];
    [self setOpacity:[aDecoder decodeFloatForKey:@"opacity"]];
    [self setMaskOnBack:[aDecoder decodeBoolForKey:@"maskOnBack"]];
    [self setAutoFill:[aDecoder decodeBoolForKey:@"autoFill"]];
    
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
    [aCoder encodeFloat:scale forKey:@"scale"];
    [aCoder encodeFloat:rotationZ forKey:@"rotationZ"];
    [aCoder encodeFloat:opacity forKey:@"opacity"];
    [aCoder encodeBool:maskOnBack forKey:@"maskOnBack"];
    [aCoder encodeBool:autoFill forKey:@"autoFill"];   
    
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


@end
