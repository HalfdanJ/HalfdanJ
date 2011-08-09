//
//  Shadows.m
//  SeMinSkygge
//
//  Created by Se Min Skygge on 08/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Shadows.h"

#import "Keystoner.h"
#import "RenderEngine.h"

@implementation Shadows

-(void)initPlugin{
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"back"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:40] named:@"niceEdgeBlur"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:40] named:@"blur"];

    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1] named:@"currentIndex"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:-1 maxValue:1] named:@"playbackSpeed"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"motionBlur"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"frontAlpha"];
    
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"flash"];
    
            [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"frontFakeShadow"];

    bufferIndex = 0;
    bufferFill = 0;
    
    [self assignMidiChannel:6]; 
}

-(void)setup{
    tracker = [GetPlugin(BlobTracker2d) getInstance:0];
    kinect = [GetPlugin(Kinect) getInstance:0];
    surface = [GetPlugin(Keystoner) getSurface:@"Screen" viewNumber:0 projectorNumber:0];
    
    for(int i=0;i<BUFFER_SIZE;i++){
        buffer[i] = new ofxCvGrayscaleImage();
        buffer[i]->allocate(1024, 768);
    }
    
    grayOutputImage = new ofxCvGrayscaleImage();
    grayOutputImage->allocate(1024,768);
    grayOutputImage->set(255);
    grayOutputImageTemp = new ofxCvGrayscaleImage();
    grayOutputImageTemp->allocate(1024,768);
    grayOutputImageTemp->set(255);
    
    
    lightImage = new ofxCvColorImage();
    lightImage->allocate(1024,768);

    NSString * file = [NSString stringWithFormat:@"%@/LightSources/Light1.jpg",[GetPlugin(RenderEngine) assetDir]];
    ofImage img;
    img.setUseTexture(false);
    if(img.loadImage([file cStringUsingEncoding:NSUTF8StringEncoding])){
    lightImage->setFromPixels(img.getPixels(),1024, 768);
    lightImage->updateTexture();
    }
    
    file = [NSString stringWithFormat:@"%@/LightSources/LightFlash.jpg",[GetPlugin(RenderEngine) assetDir]];
    lightFlashImage = new ofImage();
    lightFlashImage->loadImage([file cStringUsingEncoding:NSUTF8StringEncoding]);
    
    
    output = new ofxCvColorImage();
    output->allocate(1024,768);
    
}

-(void)update:(NSDictionary *)drawingInformation{
    trackerImageRef = [tracker grayDiff];
    bufferIndex++;
    if(bufferIndex >= BUFFER_SIZE)
        bufferIndex = 0;
    if(bufferFill < BUFFER_SIZE)
        bufferFill++;
    
    buffer[bufferIndex]->scaleIntoMe(*trackerImageRef);
    int blur = PropI(@"niceEdgeBlur");
    if(blur > 0){
        if(blur % 2 == 0) blur += 1;        
        buffer[bufferIndex]->blur(blur);
        buffer[bufferIndex]->threshold(100);
    }
    
    blur = PropI(@"blur");
    if(blur > 0){
        if(blur % 2 == 0) blur += 1;        
        buffer[bufferIndex]->blur(blur);
    }
    buffer[bufferIndex]->invert();
    buffer[bufferIndex]->updateTexture();

    int i = [self getCurrentBufferIndex];    

    cvAddWeighted( grayOutputImage->getCvImage(), PropF(@"motionBlur"), buffer[i]->getCvImage(), 1-PropF(@"motionBlur"), 1.0, grayOutputImageTemp->getCvImage());
    grayOutputImageTemp->flagImageChanged();
    grayOutputImageTemp->updateTexture();

    *grayOutputImage = *grayOutputImageTemp;
    grayOutputImage->flagImageChanged();
//    grayOutputImage->updateTexture();
    
    *output = (*grayOutputImage); 
    *output *= (*lightImage);
    
    output->updateTexture();
    *buffer[bufferIndex] = *trackerImageRef;
    
    
    float speed = PropF(@"playbackSpeed");
    [Prop(@"currentIndex") setFloatValue:ofClamp(PropF(@"currentIndex")+speed*1.0/BUFFER_SIZE, 0, 1)];

}

-(void)controlDraw:(NSDictionary *)drawingInformation{
    if([[GetPlugin(Kinect) enabled] boolValue] && [kinect kinectConnected]){
    ofBackground(0, 0, 0);
    ofEnableAlphaBlending();
    
    ofxPoint3f corners[4];
    corners[0] = [kinect convertSurfaceToWorld:ofxPoint3f(0,0,0)];
    corners[1] = [kinect convertSurfaceToWorld:ofxPoint3f([kinect surfaceAspect],0,0)];
    corners[2] = [kinect convertSurfaceToWorld:ofxPoint3f([kinect surfaceAspect],1,0)];
    corners[3] = [kinect convertSurfaceToWorld:ofxPoint3f(0,1,0)];
    for(int i=0;i<4;i++){
        corners[i] = [kinect convertWorldToKinect:ofxPoint3f(corners[i])];
    }
    
    float scaleX = (1024.0/640);
    float scaleY = (768.0/480);
    
    int i = [self getCurrentBufferIndex];    
    ofSetColor(255,255,255);
    grayOutputImage->getTextureReference().bind();
    glBegin(GL_QUADS);
    glTexCoord2f(corners[0].x*scaleX, corners[0].y*scaleY);   glVertex2d(0, 0);
    glTexCoord2f(corners[1].x*scaleX, corners[1].y*scaleY);   glVertex2d(320, 0);
    glTexCoord2f(corners[2].x*scaleX, corners[2].y*scaleY);   glVertex2d(320, 240);
    glTexCoord2f(corners[3].x*scaleX, corners[3].y*scaleY);   glVertex2d(0, 240);
    glEnd();
    grayOutputImage->getTextureReference().unbind();
        
    
    ofSetColor(255,255,255,80);
    buffer[bufferIndex]->getTextureReference().bind();
    glBegin(GL_QUADS);
    glTexCoord2f(corners[0].x*scaleX, corners[0].y*scaleY);   glVertex2d(0, 0);
    glTexCoord2f(corners[1].x*scaleX, corners[1].y*scaleY);   glVertex2d(320, 0);
    glTexCoord2f(corners[2].x*scaleX, corners[2].y*scaleY);   glVertex2d(320, 240);
    glTexCoord2f(corners[3].x*scaleX, corners[3].y*scaleY);   glVertex2d(0, 240);
    glEnd();
    buffer[bufferIndex]->getTextureReference().unbind();

        
    
    //Timeline

    glPushMatrix();{
        glTranslated(5, 250, 0);
      
        ofNoFill();
        ofSetColor(150, 150, 150);
        ofRect(0,0,310,20);
        
        //Fill
        ofFill();
        ofSetColor(100,100,150);
        ofRect(309-309.0*((float)bufferFill/BUFFER_SIZE)+1,0,309.0*((float)bufferFill/BUFFER_SIZE),19);
        
        //Current index
        ofFill();
        ofSetColor(255,255,255,100);
        ofRect(PropF(@"currentIndex")*310.0,-5,3,30);
        
        
    }glPopMatrix();
    
    
    
   /* PersistentBlob2d * pblob = [tracker getPBlob:0];
    if(pblob != nil){
        for(Blob2d * blob in [pblob blobs]){
            ofSetColor(255, 0, 0);
            glBegin(GL_LINE_STRIP);
            for (int i=0; i< [blob nPts]; i++) {
                glVertex2f([blob pts][i].x*320, [blob pts][i].y*240);
            }           
            glEnd();
        }
    }*/
        
    }
}

-(void)draw:(NSDictionary *)drawingInformation{
    ApplySurface(@"Screen");{
        if([[GetPlugin(Kinect) enabled] boolValue] && [kinect kinectConnected]){
            ofEnableAlphaBlending();
            
            ofxPoint3f corners[4];
            corners[0] = [kinect convertSurfaceToWorld:ofxPoint3f(0,0,0)];
            corners[1] = [kinect convertSurfaceToWorld:ofxPoint3f([kinect surfaceAspect],0,0)];
            corners[2] = [kinect convertSurfaceToWorld:ofxPoint3f([kinect surfaceAspect],1,0)];
            corners[3] = [kinect convertSurfaceToWorld:ofxPoint3f(0,1,0)];
            for(int i=0;i<4;i++){
                corners[i] = [kinect convertWorldToKinect:ofxPoint3f(corners[i])];
            }
            
            float scaleX = (1024.0/640);
            float scaleY = (768.0/480);
           
            if(appliedProjector == 0){
            ofSetColor(255,255,255,PropF(@"frontAlpha")*255.0*powf(1- PropF(@"back"),1.0/2.2));                
            } else {
                ofSetColor(255,255,255,255.0*powf(PropF(@"back"),1.0/2.2));                
            }

            
            ofxCvImage * img;
            img = output;
            
            img->getTextureReference().bind();
            glBegin(GL_QUADS);
            glTexCoord2f(corners[0].x*scaleX, corners[0].y*scaleY);   glVertex2d(0, 0);
            glTexCoord2f(corners[1].x*scaleX, corners[1].y*scaleY);   glVertex2d(Aspect(@"Screen",1), 0);
            glTexCoord2f(corners[2].x*scaleX, corners[2].y*scaleY);   glVertex2d(Aspect(@"Screen",1), 1);
            glTexCoord2f(corners[3].x*scaleX, corners[3].y*scaleY);   glVertex2d(0, 1);
            glEnd();
            img->getTextureReference().unbind();
            
            if(appliedProjector == 0){
                img = lightImage;
                float a = PropF(@"frontAlpha")*255.0*powf(1- PropF(@"back"),1.0/2.2);              
                ofSetColor(a,a,a, 255.0*(1-PropF(@"frontFakeShadow")));                

                
                img->getTextureReference().bind();
                glBegin(GL_QUADS);
                glTexCoord2f(corners[0].x*scaleX, corners[0].y*scaleY);   glVertex2d(0, 0);
                glTexCoord2f(corners[1].x*scaleX, corners[1].y*scaleY);   glVertex2d(Aspect(@"Screen",1), 0);
                glTexCoord2f(corners[2].x*scaleX, corners[2].y*scaleY);   glVertex2d(Aspect(@"Screen",1), 1);
                glTexCoord2f(corners[3].x*scaleX, corners[3].y*scaleY);   glVertex2d(0, 1);
                glEnd();
                img->getTextureReference().unbind();
            }
            
            ofSetColor(255,255,255,255.0*PropF(@"flash"));
            lightFlashImage->draw(0,0,Aspect(@"Screen",1),1);
            
        }
    }PopSurface();
}


-(int) getCurrentBufferIndex{
    int p = PropF(@"currentIndex")*BUFFER_SIZE;
    p += bufferIndex;
    if(p >= BUFFER_SIZE)
        p -= BUFFER_SIZE;
    return p;
}

@end
