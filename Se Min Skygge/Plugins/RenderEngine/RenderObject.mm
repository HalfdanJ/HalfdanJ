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
    [self draw];
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
    
    // Upload the texture bitmap.  (We assume it has power-of-2 dimensions.)
    GLenum format =  GL_RGBA;
    GLenum internalFormat = GL_RGBA;
    glTexImage2D( GL_TEXTURE_RECTANGLE_EXT, 0, internalFormat, width, height, 0, format, GL_UNSIGNED_BYTE, bitmapData );
}

@end



//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------


@implementation RenderObject
@synthesize engine, name, subObjects, assetString, assetInfo;
@synthesize posX, posY, posZ, scale,rotationZ;
- (id)init
{
    self = [super init];
    if (self) {
        [self addObserver:self forKeyPath:@"assetString" options:0 context:@"loadAsset"];
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if([(NSString*)context isEqualToString:@"loadAsset"]){
        [self loadAsset];
    }
}

-(void) transform{
    glTranslatef(posX, posY, posZ);
    glScaled(scale, scale,scale);
    glRotated(rotationZ, 0,0,1);
    glTranslated(-[self aspect]*0.5, -0.5, 0);
}

-(void)drawWithAlpha:(float)alpha{
    glColor4f(255,255,255,alpha*255);    
    glPushMatrix();{
        [self transform];        
        [self drawFbo];        
    }glPopMatrix();
}


-(void) drawMaskWithAlpha:(float)alpha{
    glColor4f(0,0,0,alpha*255);    
    glPushMatrix();{
        [self transform];        
        [self drawFbo];        
    }glPopMatrix();
}


-(void)renderFbo{
    if(imageTexture == 0){
        [self setupAssetOpengl];
    }
    float sigma = 11;
    float size = 4;
    
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
    
    tempFbo->clear();
    tempFbo->swapIn();{
        glPushMatrix();
        glViewport(0, 0, w, h);    
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        gluPerspective(screenFov, as, nearDist, farDist);        
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        gluLookAt(eyeX, eyeY, dist, eyeX, eyeY, 0.0, 0.0, 1.0, 0.0);        
        glScalef(1, -1, 2);   
        glTranslatef(0, -h, 0);        
        glScaled(w,h,1);            
        ofSetColor(255,255,255);
        
        ofxShader * shader = [engine blurShader];
        shader->setShaderActive(true);
        shader->setUniformVariable1f((char*)"blurSize", size);
        shader->setUniformVariable1f((char*)"direction", 0);
        shader->setUniformVariable1f((char*)"sigma", sigma);
        
        if(imageAsset != nil){
//            [self drawImageAsset];
            borderFbo->draw(0,0,1,1);
           /* ofSetColor(255, 0, 0);
            ofRect(-0.1,-0.1,1.2,1.2);

            ofSetColor(255, 255, 255);
            ofRect(0,0,1,1);
*/
        }        
        shader->setShaderActive(false);

        glPopMatrix();
        
	}tempFbo->swapOut();
    
   /* fbo->clear();
    fbo->swapIn();{
        glPushMatrix();
        glViewport(0, 0, w, h);    
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        gluPerspective(screenFov, as, nearDist, farDist);        
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        gluLookAt(eyeX, eyeY, dist, eyeX, eyeY, 0.0, 0.0, 1.0, 0.0);        
        glScalef(1, -1, 2);   
        glTranslatef(0, -h, 0);
        glScaled(w,h,1);            
        ofSetColor(255,255,255);
      
        ofxShader * shader = [engine blurShader];
        shader->setShaderActive(true);
      //  shader->setUniformVariable1f((char*)"blurSize", 10);
        shader->setUniformVariable1f((char*)"direction", 1.0);
        //shader->setUniformVariable1f((char*)"sigma", 10);
        
        tempFbo->draw(0,0,1,1);
        shader->setShaderActive(false);
        
        glPopMatrix();
        
	}fbo->swapOut();
    
    */
    
    glViewport(0,0,ofGetWidth(),ofGetHeight());    
    ofSetupScreen();
    glScaled(ofGetWidth(), ofGetHeight(), 1);       
}

-(void) drawFbo{
    glScaled(1.0/([self pixelsWide]+2*fboBorder), 1.0/([self pixelsHigh]+2*fboBorder), 1);
    glTranslated(-fboBorder, -fboBorder, 0);
    glScaled(([self pixelsWide]+4*fboBorder), ([self pixelsHigh]+4*fboBorder), 1);

    tempFbo->draw(0,0,[self aspect],1);
    
}

-(void) drawImageAsset{
    NSBitmapImageRep * rep = [[imageAsset representations] lastObject];
    
    
    glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE );
    glEnable( GL_TEXTURE_RECTANGLE_EXT );
    glBindTexture( GL_TEXTURE_RECTANGLE_EXT, imageTexture );    
    
    glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex3f(0,0,0);
    glTexCoord2f([rep pixelsWide], 0); glVertex3f(1,0,0);
    glTexCoord2f([rep pixelsWide], [rep pixelsHigh]);glVertex3f(1,1,0);
    glTexCoord2f(0, [rep pixelsHigh]); glVertex3f(0,1,0);
    glEnd();
    
    glDisable(GL_TEXTURE_RECTANGLE_EXT);         
}



-(void) drawControlsWithColor:(NSColor*)color{
    glPushMatrix();{
        [self transform];              
        glColor4f([color redComponent]*255.0, [color greenComponent]*255.0, [color blueComponent]*255.0, [color alphaComponent]*255.0);        
        glBegin(GL_LINE_STRIP);
        glVertex3f(0,0,0);
        glVertex3f([self aspect],0,0);
        glVertex3f([self aspect],1,0);
        glVertex3f(0,1,0);
        glVertex3f(0,0,0);
        glEnd();        
    }glPopMatrix();
}


-(void) loadAsset{
    [self willChangeValueForKey:@"imageRep"];
    [self willChangeValueForKey:@"assetLoaded"];    
    
    imageAsset = nil;
    imageTexture = 0;
    
    [self setAssetInfo:@"No asset"];
    
    NSURL * url = [[NSURL alloc] initFileURLWithPath:[NSString stringWithFormat:@"%@%@", [engine assetDir],[self assetString]] isDirectory:NO];
    BOOL reachable = [url checkResourceIsReachableAndReturnError:nil];
    if(!reachable){
        NSLog(@"%@ not reachable", url);
        
    } else {
        NSLog(@"%@ reachable", url);  
        imageAsset = [[NSImage alloc] initWithContentsOfURL:url];
        NSBitmapImageRep * rep = [[imageAsset representations] lastObject];
        
        NSMutableString * info = [NSMutableString string];
        [info appendString:@"Image asset\n"];
        [info appendFormat:@"Size: %ix%i",[rep pixelsWide],[rep pixelsHigh]];
        [self setAssetInfo:info];
    }
    
    [self didChangeValueForKey:@"assetLoaded"];
    [self didChangeValueForKey:@"imageRep"];   
}

-(void) setupAssetOpengl{    
    NSBitmapImageRep * rep = [[imageAsset representations] lastObject];
    glGenTextures( 1, &imageTexture );            
    [rep uploadAsOpenGLTexture:imageTexture];   
    
    //FBO
    if(tempFbo)
        delete tempFbo;
    if(fbo)
        delete fbo;
    
    tempFbo = new ofxFBOTexture();
    fbo = new ofxFBOTexture();
    borderFbo = new ofxFBOTexture();
    
    tempFbo->allocate([self pixelsWide]+2*fboBorder, [self pixelsHigh]+2*fboBorder);
    fbo->allocate([self pixelsWide]+2*fboBorder, [self pixelsHigh]+2*fboBorder);
    borderFbo->allocate([self pixelsWide]+2*fboBorder, [self pixelsHigh]+2*fboBorder);

    tempFbo->clear(0,0,0,0);
    fbo->clear(0,0,0,0);
    
    
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
    
    borderFbo->clear(0,0,0,255);
    borderFbo->swapIn();{
        glPushMatrix();
        glViewport(0, 0, w, h);    
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        gluPerspective(screenFov, as, nearDist, farDist);        
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        gluLookAt(eyeX, eyeY, dist, eyeX, eyeY, 0.0, 0.0, 1.0, 0.0);        
        glScalef(1, -1, 2);   
        glTranslatef(0, -h, 0);        
        glTranslated(fboBorder, fboBorder, 0);
        glScaled([self pixelsWide],[self pixelsHigh],1);            
        ofSetColor(255,255,255);
        
        if(imageAsset != nil){
            [self drawImageAsset];
        }        
        glPopMatrix();
	}borderFbo->swapOut();
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
    return YES;
}

-(float)backAlpha{
    if(posZ <= 0)
        return 1;
    return 0;
}

-(float)frontAlpha{
    if(posZ <= 0)
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

-(void)setEngine:(RenderEngine*)_e{
    engine = _e;
    
    [_e addObserver:self forKeyPath:@"assetDir" options:0 context:@"loadAsset"];
    [self loadAsset];
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    [self setName:[aDecoder decodeObjectForKey:@"name"]];
    [self setAssetString:[aDecoder decodeObjectForKey:@"assetString"]];
    [self setPosX:[aDecoder decodeFloatForKey:@"posX"]];
    [self setPosY:[aDecoder decodeFloatForKey:@"posY"]];
    [self setPosZ:[aDecoder decodeFloatForKey:@"posZ"]];    
    [self setScale:[aDecoder decodeFloatForKey:@"scale"]];
    [self setRotationZ:[aDecoder decodeFloatForKey:@"rotationZ"]];
    
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
}

-(NSString *)description{
    return [NSString stringWithFormat:@"RenderObject: %@",name];
}
@end
