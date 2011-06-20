
#import "ShadowFog.h"
#import "InteractiveWall.h"

@implementation ShadowFog

-(void)initPlugin{
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:40] named:@"blur"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:1 maxValue:5] named:@"blurPasses"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"motionBlur"];
    
}

-(void)setup{
    [self assignMidiChannel:8]; 
    kinect = [GetPlugin(Kinect) getInstance:1];
    surface = [GetPlugin(Keystoner) getSurface:@"Screen" viewNumber:0 projectorNumber:0];
    
    
    grayOutputImage = new ofxCvGrayscaleImage();
    grayOutputImage->allocate(1024,768);
    grayOutputImage->set(0);
    grayOutputImageTemp = new ofxCvGrayscaleImage();
    grayOutputImageTemp->allocate(1024,768);
    grayOutputImageTemp->set(0);
    grayOutputImageTemp2 = new ofxCvGrayscaleImage();
    grayOutputImageTemp2->allocate(1024,768);
    grayOutputImageTemp2->set(0);
    
}

-(void) drawPolygAtPoint:(ofxPoint2f)p radius:(float)r points:(int)n{
    CvPoint _cp2[n];
    for(int i=0;i<n;i++){
        float s = (float)i/n*TWO_PI;
        _cp2[i].x = p.x+sin(s)*r;
        _cp2[i].y = p.y+cos(s)*r;
    }
    
    CvPoint * cp = _cp2; 
    cvFillPoly(grayOutputImageTemp->getCvImage(), &cp, &n, 1, cvScalar(255));
}

-(void)update:(NSDictionary *)drawingInformation{
    //Reset temp
    grayOutputImageTemp->set(0);
    
    
    float screenDist = [[[GetPlugin(InteractiveWall) properties] objectForKey:@"screenDist"] floatValue];      
    float kinectRes = [[[GetPlugin(InteractiveWall) properties] objectForKey:@"kinectRes"] floatValue];
    
    vector<ofxPoint3f> p = [kinect getPointsInBoxXMin:0 xMax:Aspect(@"Screen",1) yMin:0 yMax:1 zMin:-1000 zMax:-screenDist res:kinectRes];
    
    for(int i=0;i<p.size();i++){
        ofxPoint3f kinectP = [kinect convertWorldToKinect:[kinect convertSurfaceToWorld:p[i]]];        
        ofxPoint2f warped = [kinect coordWarper]->transform(kinectP.x/640.0, kinectP.y/480.0);
        
        [self drawPolygAtPoint:warped radius:10.0 points:10];        
    }
    
    int blur = PropI(@"niceEdgeBlur");
    if(blur > 0){
        if(blur % 2 == 0) blur += 1;            
        for(int i=0;i<PropI(@"blurPasses");i++){
            grayOutputImageTemp->blur(blur);
        }
    }
    
    cvAddWeighted( grayOutputImage->getCvImage(), PropF(@"motionBlur"), grayOutputImageTemp->getCvImage(), 1-PropF(@"motionBlur"), 1.0, grayOutputImageTemp2->getCvImage());
    grayOutputImageTemp2->flagImageChanged();
    grayOutputImageTemp2->updateTexture();
    
    *grayOutputImage = *grayOutputImageTemp2;
    grayOutputImage->flagImageChanged();    
}

-(void)draw:(NSDictionary *)drawingInformation{
    ApplySurface(@"Screen");{
        if([[GetPlugin(Kinect) enabled] boolValue] && [kinect kinectConnected]){
            if(appliedProjector == 0){            
                
                ofEnableAlphaBlending();
             
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
                
                ofSetColor(255,255,255,255.0);
                
                grayOutputImage->getTextureReference().bind();
                glBegin(GL_QUADS);
                glTexCoord2f(corners[0].x*scaleX, corners[0].y*scaleY);   glVertex2d(0, 0);
                glTexCoord2f(corners[1].x*scaleX, corners[1].y*scaleY);   glVertex2d(Aspect(@"Screen",1), 0);
                glTexCoord2f(corners[2].x*scaleX, corners[2].y*scaleY);   glVertex2d(Aspect(@"Screen",1), 1);
                glTexCoord2f(corners[3].x*scaleX, corners[3].y*scaleY);   glVertex2d(0, 1);
                glEnd();
                grayOutputImage->getTextureReference().unbind();
            }
            
        }
    } PopSurface();
}
@end
