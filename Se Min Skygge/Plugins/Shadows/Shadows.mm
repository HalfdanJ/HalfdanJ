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
#include "TextureGrid.h"

@implementation Shadows
@synthesize timeline;

-(void)initPlugin{
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"back"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:40] named:@"niceEdgeBlur"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:40] named:@"blur"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1] named:@"currentIndex"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:-1 maxValue:1] named:@"playbackSpeed"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:10] named:@"motionBlur"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:10] named:@"motionBlurPasses"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"frontAlpha"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"flash"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"frontFakeShadow"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:1 maxValue:10] named:@"blurPass"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:10] named:@"blurAm"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"motionBlurFade"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:10] named:@"timelineTime"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:10] named:@"inputGain"];
    
    [self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named:@"useOpenCV"];
    [self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named:@"useShaders"];
    
    [self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named:@"reloadShaders"];
    [self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named:@"reloadImages"];
    
    [self addProperty:[BoolProperty boolPropertyWithDefaultvalue:0.0] named:@"debug"];
    
    bufferIndex = 0;
    bufferFill = 0;
    
    [self assignMidiChannel:6]; 
    
    [self loadTimeline];

    
}

-(void) loadTimeline{
    NSString * path = [NSString stringWithCString:ofToDataPath("timeline.txt",true).c_str() encoding:NSUTF8StringEncoding];
    [self setTimeline:[NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path isDirectory:NO] encoding:NSUTF8StringEncoding error:nil]];

    NSRange _start = [timeline rangeOfString:@"	Frame	seconds	"];
    NSRange _stop = [timeline rangeOfString:@"End of Keyframe Data"];
    
    if(_start.location == NSNotFound || _stop.location == NSNotFound){
        NSLog(@"\n\n\n=====================\n\nERROR: Timeline not correct! Start or stop not found\n\n\n");
    }
    
    NSString * substring = [timeline substringWithRange:NSMakeRange(_start.location+_start.length, _stop.location-(_start.location+_start.length))];
    [self setTimeline:substring];
    
    NSArray *listItems = [substring componentsSeparatedByString:@"	"];

    int i=0;
    for(NSString * str in listItems){
        NSLog(@"%i %i %@",i,i%3,str);
        if(i%3 == 1){
            keyframe nKeyframe;
            nKeyframe.time = [str intValue]/25.0;
            keyframes.push_back(nKeyframe);
        } else if(i%3 == 2){
            keyframes[keyframes.size()-1].value = [str floatValue] - keyframes[keyframes.size()-1].time ;
        }
        i++;
    }
    
    for(int i=0;i<keyframes.size();i++){
        cout<<"keyframe "<<keyframes[i].time<<"-"<<keyframes[i].value<<endl;
    }

}

-(void)setup{
    
    tracker = [GetPlugin(BlobTracker2d) getInstance:0];
    kinect = [GetPlugin(Kinect) getInstance:0];
    surface = [GetPlugin(Keystoner) getSurface:@"Screen" viewNumber:0 projectorNumber:0];
    
    for(int i=0;i<BUFFER_SIZE;i++){
        buffer[i] = new ofxCvGrayscaleImage();
        buffer[i]->allocate(1024, 768);
        
        history[i] = new ofxFBOTexture();
        history[i]->allocate(640, 480);
     //   history[i]->clear(0,0,0,1);
    }
      
  /*  grayOutputImage = new ofxCvGrayscaleImage();
    grayOutputImage->allocate(1024,768);
    grayOutputImage->set(255);
    grayOutputImageTemp = new ofxCvGrayscaleImage();
    grayOutputImageTemp->allocate(1024,768);
    grayOutputImageTemp->set(255);
    */
    
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
    
    [Prop(@"reloadShaders") setBoolValue:1];
    [Prop(@"reloadImages") setBoolValue:1];
    
    motionblurFbo[0] = new ofxFBOTexture();
    motionblurFbo[0]->allocate(1024,768);
  //  motionblurFbo[0]->clear(0,0,0,1);
    motionblurFbo[1] = new ofxFBOTexture();
    motionblurFbo[1]->allocate(1024,768);
  //  motionblurFbo[1]->clear(0,0,0,1);
    
    blur = new shaderBlur();
    blur->setup(400,300);
    
    blurHist = new shaderBlur();
    blurHist->setup(400,300);
    
  
    
}

-(void)update:(NSDictionary *)drawingInformation{
    if(PropB(@"reloadShaders")){
        [Prop(@"reloadShaders") setBoolValue:0];
        //        shader = new ofxShader();
        shader.setup("curvesShader");
    }
    if(PropB(@"reloadImages")){
        [Prop(@"reloadImages") setBoolValue:0];
        //        rampImg = new ofImage();
        rampImg.loadImage("Ramp.png");
        
    }
    
    //
    //  if([tracker grayBg]->
    //ofxCvGrayscaleImage * img = [tracker grayBg];
    //        *bgCache = *[tracker grayBg];
    //    cout<<[tracker grayBg]->getPixels()[0]<<endl;
    
    /*    trackerImageRef = [tracker grayDiff];
     bufferIndex++;
     if(bufferIndex >= BUFFER_SIZE)
     bufferIndex = 0;
     if(bufferFill < BUFFER_SIZE)
     bufferFill++;
     
     buffer[bufferIndex]->scaleIntoMe(*trackerImageRef);
     int _blur = PropI(@"niceEdgeBlur");
     if(_blur > 0){
     if(_blur % 2 == 0) _blur += 1;        
     buffer[bufferIndex]->blur(_blur);
     buffer[bufferIndex]->threshold(100);
     }
     
     _blur = PropI(@"blur");
     if(_blur > 0){
     if(_blur % 2 == 0) _blur += 1;        
     buffer[bufferIndex]->blur(_blur);
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
     //  *buffer[bufferIndex] = *trackerImageRef;
     
     */
     float speed = PropF(@"playbackSpeed");
     [Prop(@"currentIndex") setFloatValue:ofClamp(PropF(@"currentIndex")+speed*1.0/BUFFER_SIZE, 0, 1)];
     
}

-(float)valueForTime:(float)time{
    keyframe l,r;
    
    l.time = -1;
    r.time = -1;
    
    for(int i=0;i<keyframes.size();i++){
        if(l.time == -1 || keyframes[i].time <= time)
            l = keyframes[i];
        if(r.time == -1 && keyframes[i].time >= time)
            r = keyframes[i];
    }
    
    if(l.time == -1 || r.time == -1){
        cout<<"No timeline for time "<<time<<endl;
        return 0;
    } 
    
    float p = (time - l.time) / (r.time-l.time);
    
    return (1-p) * l.value + p*r.value;
}

-(void)controlDraw:(NSDictionary *)drawingInformation{
 /*  if([[GetPlugin(Kinect) enabled] boolValue] && [kinect kinectConnected]){
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
        history[bufferIndex]->bind();
        glBegin(GL_QUADS);
        glTexCoord2f(corners[0].x, corners[0].y);   glVertex2d(0, 0);
        glTexCoord2f(corners[1].x, corners[1].y);   glVertex2d(320, 0);
        glTexCoord2f(corners[2].x, corners[2].y);   glVertex2d(320, 240);
        glTexCoord2f(corners[3].x, corners[3].y);   glVertex2d(0, 240);
        glEnd();
        history[bufferIndex]->unbind();
        
        
        
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
        }
    
        //Real timeline (!)
        glPushMatrix();{
            glTranslated(5, 180, 0);
            
            ofNoFill();
            ofSetColor(150, 150, 150);
            ofRect(0,0,310,70);
            
            if(keyframes.size() > 1){
                glPushMatrix();
                glTranslated(0,70,0);
                
                float d = keyframes[keyframes.size()-1].time - keyframes[0].time;
                
                glColor3d(0,0,255);
                glBegin(GL_LINE_STRIP);
                for(int i=0;i<keyframes.size();i++){
                    glVertex2d(309.0 * keyframes[i].time/d, 70.0 * keyframes[i].value/10.0);
                }
                glEnd();

                glPopMatrix();
                
                ofSetColor(0, 255, 0);
                
                float x = PropF(@"timelineTime")*309.0/d;
                ofLine(x, 0, x, 70);
                ofCircle(x, [self valueForTime:PropF(@"timelineTime")]*7.0+70, 4);
                
            }
            
                        
        }glPopMatrix();
        
             
    }
   */
}

-(void)draw:(NSDictionary *)drawingInformation{
    ofxPoint2f corners[4];
    for(int i=0;i<4;i++){
        corners[i] = [kinect surfaceCorner:i];
    }
    
    
    
    
    
    
    
    if(!PropB(@"useOpenCV")) {    
        ofTexture * tex = [kinect getIRGenerator]->getTexture();
        
        //Blur input
        blur->setBlurParams(PropI(@"blurPass"), PropF(@"blurAm"));
        blur->beginRender();{
            glPushMatrix();
            
            ofSetColor(0, 0,0);
            ofRect(0,0,1,1);
            
            ofSetColor(255,255,255);
            BOOL useShader = PropB(@"useShaders");
            
            if(useShader){
                shader.begin();
                shader.setTexture("texRamp", rampImg.getTextureReference() , 1);
                shader.setTexture("texBG", ([tracker grayBg]->getTextureReference()) , 2);
                shader.setUniform("inputGain",float(PropF(@"inputGain")*10.0));
            }
            
            ofxPoint2f poly[4];            
            poly[0] = ofxPoint2f(0.0,0.0);
            poly[1] = ofxPoint2f(1,0.0);
            poly[2] = ofxPoint2f(1,1.0);
            poly[3] = ofxPoint2f(0.0,1.0);      
            
            TextureGrid texGrid;
            texGrid.drawTextureGrid(tex,  poly, corners, 10);
     
            
            if(useShader){
                shader.end();
            }
            glPopMatrix();
            if(PropB(@"debug")){
                ofSetColor(255, 0, 0);
                ofEllipse(0.3,0.3,0.2,0.2);
            }
        }  blur->endRender();
        ofEnableAlphaBlending();
        
        
        glPushMatrix();
        //Buffer
        {
            bufferIndex++;
            if(bufferIndex >= BUFFER_SIZE)
                bufferIndex = 0;
            if(bufferFill < BUFFER_SIZE)
                bufferFill++;
            
            //cout<<"Render to "<<bufferIndex<<endl;
            
            history[bufferIndex]->swapIn();{
                history[bufferIndex]->setupScreenForThem();
                blur->draw(0,0,1,1);
            }history[bufferIndex]->swapOut();     
            history[bufferIndex]->setupScreenForMe();
        }
        glPopMatrix();
        
        
        ofSetColor(255, 255, 255);
        
        //Blur history
        blurHist->setBlurParams(PropI(@"motionBlurPasses"), PropF(@"motionBlur"));
        blurHist->beginRender();{
            motionblurFbo[pingpong]->draw(0,0,1,1);
        }  blurHist->endRender();
        ofEnableAlphaBlending();
        
        ofSetColor(255, 255, 255);
        
        //Motion blur
        pingpong = !pingpong;
        
        motionblurFbo[pingpong]->clear(0,0,0,1);
        motionblurFbo[pingpong]->swapIn();{
            motionblurFbo[pingpong]->setupScreenForThem();
            
            //ofDisableAlphaBlending();
            
            ofSetColor(255,255,255,255);
            //motionblurFbo[!pingpong]->draw(0,0,1,1);
            blurHist->draw(0,0,1,1,false);
            
            glBlendFunc(GL_ZERO, GL_SRC_COLOR);
            ofSetColor(255.0*(1-PropF(@"motionBlurFade")), 255.0*(1-PropF(@"motionBlurFade")), 255.0*(1-PropF(@"motionBlurFade")));
            ofRect(0,0, 1, 1);
            
            glEnable(GL_BLEND);
            ofEnableAlphaBlending();
            glBlendFunc(GL_ONE, GL_ONE);
            ofSetColor(255, 255, 255,255);
            //        blur->draw(0.0,0,1,1,true);
            // ofRect(0.1, 0.1, 0.8, 0.8);

            //blur->draw(0,0,1,1,false);
            int i = [self getCurrentBufferIndex];    
            //cout<<"Draw "<<i<<endl;
            history[i]->draw(0,0,1,1);
            
        }motionblurFbo[pingpong]->swapOut();    
        ofEnableAlphaBlending();
        motionblurFbo[pingpong]->setupScreenForMe();
        
        
        
        
        ApplySurface(@"Screen");{
            ofFill();
            ofSetColor(255, 255, 255);
            if(PropB(@"debug")){
                motionblurFbo[pingpong]->draw(0.5,0.5,0.5,0.5);
                blurHist->draw(0.,0.5,0.5,0.5,true);
                blur->draw(0.5,0.,0.5,0.5,true);
                
                tex->bind();
                glBegin(GL_QUADS);
                glTexCoord2f(corners[0].x, corners[0].y);   glVertex2d(0, 0);
                glTexCoord2f(corners[1].x, corners[1].y);   glVertex2d(0.5, 0);
                glTexCoord2f(corners[2].x, corners[2].y);   glVertex2d(.5, .5);
                glTexCoord2f(corners[3].x, corners[3].y);   glVertex2d(0, .5);
                glEnd();
                tex->unbind();
                
                [tracker grayBg]->getTextureReference().bind();
                glBegin(GL_QUADS);
                glTexCoord2f(corners[0].x, corners[0].y);   glVertex2d(0.5, 0);
                glTexCoord2f(corners[1].x, corners[1].y);   glVertex2d(1, 0);
                glTexCoord2f(corners[2].x, corners[2].y);   glVertex2d(1, .5);
                glTexCoord2f(corners[3].x, corners[3].y);   glVertex2d(0.5, .5);
                glEnd();
                [tracker grayBg]->getTextureReference().unbind();
                
            } else {                
                if(appliedProjector == 0){
                    ofSetColor(255,255,255,PropF(@"frontAlpha")*255.0*powf(1- PropF(@"back"),1.0/2.2));                
                } else {
                    ofSetColor(255,255,255,255.0*powf(PropF(@"back"),1.0/2.2));                
                }
                lightImage->draw(0,0,Aspect(@"Screen",1),1);
          //      ofRect(0,0,1,1);        
                glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_COLOR);     
               motionblurFbo[pingpong]->draw(0,0,Aspect(@"Screen",1),1);
                
                
               // int i = [self getCurrentBufferIndex];    
                //cout<<"Draw "<<i<<endl;
                //history[i]->draw(0,0,Aspect(@"Screen",1),1);


            }
        } PopSurface();
        
        ofEnableAlphaBlending();
    }
    
   /* if(PropB(@"useOpenCV")){
        
        ApplySurface(@"Screen");{
            if([[GetPlugin(Kinect) enabled] boolValue] && [kinect kinectConnected]){
                ofEnableAlphaBlending();
                
                
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
                
            } 
            
            ofSetColor(255,255,255,255.0*PropF(@"flash"));
            lightFlashImage->draw(0,0,Aspect(@"Screen",1),1);
            
            ofSetColor(255,255,255,255.0);
            
            
        }PopSurface();
        
    }*/
   
}




-(int) getCurrentBufferIndex{
    int p = PropF(@"currentIndex")*BUFFER_SIZE;
    p += bufferIndex;
    if(p >= BUFFER_SIZE)
        p -= BUFFER_SIZE;
    return p;
}

@end
