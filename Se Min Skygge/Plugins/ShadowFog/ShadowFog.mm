
#import "ShadowFog.h"
#import "InteractiveWall.h"

@implementation ShadowFog

-(void)initPlugin{
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:100] named:@"blurBack"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:100] named:@"blurFront"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:1 maxValue:15] named:@"blurPasses"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"motionBlur"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:100] named:@"radiusBack"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:30] named:@"radiusFront"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"alphaFront"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"alphaBack"];    
    
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:0 maxValue:1] named:@"colorR"];    
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"colorG"];    
            [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"colorB"];    
}

-(void)setup{
    [self assignMidiChannel:8]; 
    kinect = [GetPlugin(Kinect) getInstance:1];
    surface = [GetPlugin(Keystoner) getSurface:@"Screen" viewNumber:0 projectorNumber:0];
    
    
    grayOutputImage = new ofxCvGrayscaleImage();
    grayOutputImage->allocate(1024,768);
    grayOutputImage->set(0);
    grayOutputImageFront = new ofxCvGrayscaleImage();
    grayOutputImageFront->allocate(1024,768);
    grayOutputImageFront->set(0);
    grayOutputImageTemp = new ofxCvGrayscaleImage();
    grayOutputImageTemp->allocate(1024,768);
    grayOutputImageTemp->set(0);
    grayOutputImageFrontTemp = new ofxCvGrayscaleImage();
    grayOutputImageFrontTemp->allocate(1024,768);
    grayOutputImageFrontTemp->set(0);
    grayOutputImageTemp2 = new ofxCvGrayscaleImage();
    grayOutputImageTemp2->allocate(1024,768);
    grayOutputImageTemp2->set(0);
    
}

-(void) drawPolygAtPoint:(ofxPoint2f)p radius:(float)r points:(int)n{
    CvPoint _cp2[n];
    for(int i=0;i<n;i++){
        float s = (float)i/n*TWO_PI;
        _cp2[i].x = 1024.0*p.x+sin(s)*r;
        _cp2[i].y = 768.0*p.y+cos(s)*r;
    }
    
    CvPoint * cp = _cp2; 
    cvFillPoly(grayOutputImageTemp->getCvImage(), &cp, &n, 1, cvScalar(255));
}
//
//-(void) drawBlackPolygAtPoint:(ofxPoint2f)p radius:(float)r points:(int)n{
//    CvPoint _cp2[n];
//    for(int i=0;i<n;i++){
//        float s = (float)i/n*TWO_PI;
//        _cp2[i].x = 640.0*p.x+sin(s)*r;
//        _cp2[i].y = 480.0*p.y+cos(s)*r;
//    }
//    
//    CvPoint * cp = _cp2; 
//    cvFillPoly(grayOutputImageFrontTemp->getCvImage(), &cp, &n, 1, cvScalar(0));
//}

-(void)update:(NSDictionary *)drawingInformation{
    //Reset temp
    
    
    float screenDist = [[[GetPlugin(InteractiveWall) properties] objectForKey:@"screenDist"] floatValue];      
    float kinectRes = [[[GetPlugin(InteractiveWall) properties] objectForKey:@"kinectRes"] floatValue];
    int blurBack = PropI(@"blurBack");
    int blurFront = PropI(@"blurFront");
    
    vector<ofxPoint3f> p = [kinect getPointsInBoxXMin:0 xMax:Aspect(@"Screen",1) yMin:0 yMax:1 zMin:-1000 zMax:-screenDist res:kinectRes];
    
    //Create back cloud    
    grayOutputImageTemp->set(0);    
    for(int i=0;i<p.size();i++){
        ofxPoint3f kinectP = [kinect convertWorldToKinect:[kinect convertSurfaceToWorld:p[i]]];        
        ofxPoint2f warped = [kinect coordWarper]->transform(kinectP.x/640.0, kinectP.y/480.0);        
        [self drawPolygAtPoint:warped radius:PropF(@"radiusBack") points:10];        
    }
    
    *grayOutputImageFrontTemp = *grayOutputImageTemp;
    
    if(blurBack > 0){
        if(blurBack % 2 == 0) blurBack += 1;            
        for(int i=0;i<PropI(@"blurPasses");i++){
            grayOutputImageTemp->blur(blurBack);
        }
    }    
    
    //Motion blur back
    cvAddWeighted( grayOutputImage->getCvImage(), PropF(@"motionBlur"), grayOutputImageTemp->getCvImage(), 1-PropF(@"motionBlur"), 1.0, grayOutputImageTemp2->getCvImage());
    grayOutputImageTemp2->flagImageChanged();
   // grayOutputImageTemp2->updateTexture();
    
    *grayOutputImage = *grayOutputImageTemp2;
    grayOutputImage->flagImageChanged();    
    grayOutputImage->updateTexture();
    
    
    /*  //Front
     for(int i=0;i<p.size();i++){
     ofxPoint3f kinectP = [kinect convertWorldToKinect:[kinect convertSurfaceToWorld:p[i]]];        
     ofxPoint2f warped = [kinect coordWarper]->transform(kinectP.x/640.0, kinectP.y/480.0);        
     [self drawBlackPolygAtPoint:warped radius:PropF(@"radiusFront") points:10];        
     }
     if(blurFront > 0){
     if(blurFront % 2 == 0) blurFront += 1;            
     for(int i=0;i<PropI(@"blurPasses");i++){
     grayOutputImageFrontTemp->blur(blurFront);
     }
     } 
     
     //Motion blur back
     cvAddWeighted( grayOutputImageFront->getCvImage(), PropF(@"motionBlur"), grayOutputImageFrontTemp->getCvImage(), 1-PropF(@"motionBlur"), 1.0, grayOutputImageTemp2->getCvImage());
     grayOutputImageTemp2->flagImageChanged();
     grayOutputImageTemp2->updateTexture();
     
     *grayOutputImageFront = *grayOutputImageTemp2;
     grayOutputImageFront->flagImageChanged();    
     grayOutputImageFront->updateTexture();*/
}

-(void)draw:(NSDictionary *)drawingInformation{
    if([[GetPlugin(Kinect) enabled] boolValue] && [kinect kinectConnected]){
        
        float scaleX = (1024.0/640);
        float scaleY = (768.0/480);
        
        ofxPoint3f corners[4];
        corners[0] = [kinect convertSurfaceToWorld:ofxPoint3f(0,0,0)];
        corners[1] = [kinect convertSurfaceToWorld:ofxPoint3f([kinect surfaceAspect],0,0)];
        corners[2] = [kinect convertSurfaceToWorld:ofxPoint3f([kinect surfaceAspect],1,0)];
        corners[3] = [kinect convertSurfaceToWorld:ofxPoint3f(0,1,0)];
        for(int i=0;i<4;i++){
            corners[i] = [kinect convertWorldToKinect:ofxPoint3f(corners[i])];
        }
        
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA,GL_ONE);
        

        ApplySurface(@"Screen");{
            if(appliedProjector == 0){            
                
                
                ofSetColor(255.0*PropF(@"colorR"),255.0*PropF(@"colorG"),255.0*PropF(@"colorB"),255.0*PropF(@"alphaFront"));                
                
                
            }
            if(appliedProjector == 1){            
                
                
                ofSetColor(255.0*PropF(@"colorR"),255.0*PropF(@"colorG"),255.0*PropF(@"colorB"),255.0*PropF(@"alphaBack"));                
                
            }
            
            //Draw
            grayOutputImage->getTextureReference().bind();
            glBegin(GL_QUADS);
            glTexCoord2f(corners[0].x*scaleX, corners[0].y*scaleY);   glVertex2d(Aspect(@"Screen",1), 0);
            glTexCoord2f(corners[1].x*scaleX, corners[1].y*scaleY);   glVertex2d(0, 0);
            glTexCoord2f(corners[2].x*scaleX, corners[2].y*scaleY);   glVertex2d(0, 1);
            glTexCoord2f(corners[3].x*scaleX, corners[3].y*scaleY);   glVertex2d(Aspect(@"Screen",1), 1);
            glEnd();
            grayOutputImage->getTextureReference().unbind();
            
            
        } PopSurface();
    }
}
@end
