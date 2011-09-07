
#import "InteractiveWall.h"
#import "Keystoner.h"

@implementation InteractiveWall

-(void)initPlugin{
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:10 minValue:1 maxValue:128] named:@"numBars"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:1 maxValue:10] named:@"speed"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"screenDist"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:49 minValue:0 maxValue:50] named:@"kinectRes"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:0.5] named:@"margin"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"edge"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:1 maxValue:10] named:@"depth"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"topBars"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"bottomBars"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"leftBars"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"rightBars"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:0 maxValue:1] named:@"backgroundr"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:0 maxValue:1] named:@"backgroundg"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:0 maxValue:1] named:@"backgroundb"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:0 maxValue:1] named:@"3dlines"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"portal"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:0 maxValue:1] named:@"alpha"];

    [self addProperty:[BoolProperty boolPropertyWithDefaultvalue:NO] named:@"reset"];
    [self addProperty:[BoolProperty boolPropertyWithDefaultvalue:NO] named:@"drawDebug"];
    
    
    [Prop(@"backgroundr") setMidiSmoothing:0.9];
    [Prop(@"backgroundg") setMidiSmoothing:0.9];
    [Prop(@"backgroundb") setMidiSmoothing:0.9];
}



-(void)setup{
    kinect = [GetPlugin(Kinect) getInstance:1];
    [self assignMidiChannel:7]; 
}



-(void)update:(NSDictionary *)drawingInformation{
    int num = bars.size();
    float aspect = Aspect(@"Screen",1);    
    float w = (float) aspect / num;
    
    
    if(PropB(@"reset")){
        [Prop(@"reset") setBoolValue:NO];
        bars.clear();
        bars2.clear();
    }
    
    while(bars.size() < PropI(@"numBars")){
        bar newBar;
        newBar.val = 0;
        newBar.filter.setStartValue(0);        
        bars.push_back(newBar);
        bars2.push_back(newBar);
        
        bars[bars.size()-1].goal = 1-PropF(@"portal");
        bars2[bars.size()-1].goal = PropF(@"portal");

        for(int i=0;i<100;i++){
            bars[bars.size()-1].val = bars[bars.size()-1].filter.filter(PropF(@"topBars")*bars[bars.size()-1].goal*1000);
            bars2[bars.size()-1].val = bars2[bars.size()-1].filter.filter((1-PropF(@"bottomBars"))*1000 + PropF(@"bottomBars")*bars2[bars.size()-1].goal*1000);
        }

    }
    while(bars.size() > PropI(@"numBars")){
        bars.pop_back();
        bars2.pop_back();
    }
    
    //Reset bars
    for(int i=0;i<bars.size();i++){
        bars[i].goal = 1-PropF(@"portal");
        bars2[i].goal = PropF(@"portal");
    }
    leftBar.goal = 0;
    rightBar.goal = aspect;    
    
    vector<ofxPoint3f> p = [kinect getPointsInBoxXMin:0 xMax:Aspect(@"Screen",1) yMin:0 yMax:1 zMin:-1000 zMax:-PropF(@"screenDist") res:PropF(@"kinectRes")];
    for(int i=0;i<p.size();i++){
        ofxPoint3f kinectP = [kinect convertWorldToKinect:[kinect convertSurfaceToWorld:p[i]]];        
        ofxPoint2f warped = [kinect coordWarper]->transform(kinectP.x/640.0, kinectP.y/480.0);
        
        int j = floor(warped.x * num);
        if(bars[j].goal > warped.y-PropF(@"margin")){
            bars[j].goal = warped.y-PropF(@"margin");
        }
        if(bars2[j].goal < warped.y+PropF(@"margin")){
            bars2[j].goal = warped.y+PropF(@"margin");
        }
        
        if(leftBar.goal > warped.x-PropF(@"margin")){
            leftBar.goal = warped.x-PropF(@"margin");
        }
        if(rightBar.goal < warped.x+PropF(@"margin")){
            rightBar.goal = warped.x+PropF(@"margin");
        }
    }
    
    
    for(int j=0;j<PropI(@"speed");j++){
        for(int i=0;i<bars.size();i++){
            bars[i].val = bars[i].filter.filter(PropF(@"topBars")*bars[i].goal*1000);
            bars[i].val = bars[i].filter.filter(PropF(@"topBars")*bars[i].goal*1000);
            bars2[i].val = bars2[i].filter.filter((1-PropF(@"bottomBars"))*1000 + PropF(@"bottomBars")*bars2[i].goal*1000);
            bars2[i].val = bars2[i].filter.filter((1-PropF(@"bottomBars"))*1000 + PropF(@"bottomBars")*bars2[i].goal*1000);
            bars[i].val = bars[i].filter.filter(PropF(@"topBars")*bars[i].goal*1000);
            bars[i].val = bars[i].filter.filter(PropF(@"topBars")*bars[i].goal*1000);
            bars2[i].val = bars2[i].filter.filter((1-PropF(@"bottomBars"))*1000 + PropF(@"bottomBars")*bars2[i].goal*1000);
            bars2[i].val = bars2[i].filter.filter((1-PropF(@"bottomBars"))*1000 + PropF(@"bottomBars")*bars2[i].goal*1000);
        }
    }
    leftBar.val = leftBar.filter.filter(PropF(@"leftBars")*leftBar.goal*1000);
    rightBar.val = rightBar.filter.filter((1-PropF(@"rightBars"))*1000*aspect + PropF(@"rightBars")*rightBar.goal*1000);
    
}

-(void)draw:(NSDictionary *)drawingInformation{
    ofFill();
    int num = bars.size();
    float aspect = Aspect(@"Screen",1);
    
    float w = (float) aspect / num;
    
    ApplySurface(@"Screen");{
        if(appliedProjector == 0){
            ofSetColor(255*PropF(@"backgroundr"),255*PropF(@"backgroundg"),255*PropF(@"backgroundb"),PropF(@"alpha")*255.0);
            ofRect(0,0,aspect,1);
        }
        if(appliedProjector == 1){
            ofSetColor(255,255,255,PropF(@"alpha")*255.);
            ofRect(0,0,aspect,1);
            
            
            
            
            for(int i=0;i<num;i++){
                for(int j=0;j<PropI(@"depth");j++){
                    ofSetColor(0, 0, 0, PropF(@"alpha")*255.0*(float)(j+1)/PropI(@"depth"));
                    float h = bars[i].val/1000.0;                    
                    //  h = h*(float)(j+1)/PropI(@"depth") + 1-(float)(j+1)/PropI(@"depth");                    
                    
                    ofRect(i*w,0,w-PropF(@"edge")*0.05,h);
                    
                    h = bars2[i].val/1000.0;                    
                    // h = h*(float)(j+1)/PropI(@"depth") + 1-(float)(j+1)/PropI(@"depth");                    
                    
                    ofRect(i*w,h,w-PropF(@"edge")*0.05,1);
                }
            }
            /*   ofSetColor(255,0,0);
             float h = leftBar.val/1000.0;                    
             ofRect(0,0,h,1);
             h = rightBar.val/1000.0;                    
             ofRect(h,0,aspect,1);
             */
            
            if(PropB(@"drawDebug")){
                ofSetColor(255,0,0);
                vector<ofxPoint3f> p = [kinect getPointsInBoxXMin:0 xMax:Aspect(@"Screen",1) yMin:0 yMax:1 zMin:-1000 zMax:-PropF(@"screenDist") res:PropF(@"kinectRes")];
                
                for(int i=0;i<p.size();i++){
                    
                    ofxPoint3f kinectP = [kinect convertWorldToKinect:[kinect convertSurfaceToWorld:p[i]]];        
                    ofxPoint2f warped = [kinect coordWarper]->transform(kinectP.x/640.0, kinectP.y/480.0);
                    
                    /*ofSetColor(255,0,0);
                     ofRect(p[i].x,p[i].y,0.01,0.01);
                     */
                    ofSetColor(0,255,0);
                    ofRect(warped.x*aspect,warped.y,0.01,0.01);
                }
            }
        }
        
        if(appliedProjector == 1 && PropF(@"3dlines") > 0){
            ofSetColor(255.0,255.0,255.0,255.0*PropF(@"3dlines"));
            for(int i=0;i<num;i++){
                glPushMatrix();
                glTranslatef(0,0,200);
                ofLine(i*w,0,i*w,1);
                glPopMatrix();
            }
        }
        if(appliedProjector == 0 && PropF(@"3dlines") > 0){
            ofSetColor(255.0,255.0,255.0,255.0*PropF(@"3dlines"));
            for(int i=0;i<num;i++){
                ofLine(i*w,0,i*w,1);
            }
        }
    } PopSurface();
}

@end
