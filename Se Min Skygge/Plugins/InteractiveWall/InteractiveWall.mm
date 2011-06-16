
#import "InteractiveWall.h"
#import "Keystoner.h"

@implementation InteractiveWall

-(void)initPlugin{
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:10 minValue:1 maxValue:30] named:@"numBars"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.5 minValue:0 maxValue:1] named:@"speed"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"screenDist"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:49 minValue:0 maxValue:50] named:@"kinectRes"];
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:0.5] named:@"margin"];
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"edge"];
    
    [self addProperty:[BoolProperty boolPropertyWithDefaultvalue:NO] named:@"reset"];
    [self addProperty:[BoolProperty boolPropertyWithDefaultvalue:NO] named:@"drawDebug"];

}



-(void)setup{
    kinect = [GetPlugin(Kinect) getInstance:1];
    
}



-(void)update:(NSDictionary *)drawingInformation{
    int num = bars.size();
    float aspect = Aspect(@"Screen",1);    
    float w = (float) aspect / num;
    
    
    if(PropB(@"reset")){
        [Prop(@"reset") setBoolValue:NO];
        bars.clear();
    }
    
    if(bars.size() < PropI(@"numBars")){
        bar newBar;
        newBar.val = 0;
        newBar.filter.setStartValue(0);
        
        bars.push_back(newBar);
    }
    while(bars.size() > PropI(@"numBars")){
        bars.pop_back();
    }

    //Reset bars
    for(int i=0;i<bars.size();i++){
        bars[i].goal = 1;
    }
        
    vector<ofxPoint3f> p = [kinect getPointsInBoxXMin:0 xMax:Aspect(@"Screen",1) yMin:0 yMax:1 zMin:-1000 zMax:-PropF(@"screenDist") res:PropF(@"kinectRes")];
    for(int i=0;i<p.size();i++){
        ofxPoint3f kinectP = [kinect convertWorldToKinect:[kinect convertSurfaceToWorld:p[i]]];        
        ofxPoint2f warped = [kinect coordWarper]->transform(kinectP.x/640.0, kinectP.y/480.0);
        
        int j = floor(warped.x * num);
        if(bars[j].goal > warped.y-PropF(@"margin")){
            bars[j].goal = warped.y-PropF(@"margin");
        }
    }
    
    for(int i=0;i<bars.size();i++){
        bars[i].val = bars[i].filter.filter(bars[i].goal*1000);
    }
}

-(void)draw:(NSDictionary *)drawingInformation{
    int num = bars.size();
    float aspect = Aspect(@"Screen",1);
    
    float w = (float) aspect / num;
    
    ApplySurfaceForProjector(@"Screen",1);{
        
        ofSetColor(255,255,255);
        ofRect(0,0,aspect,1);
        
        ofSetColor(0, 0, 0);
        for(int i=0;i<num;i++){
            ofRect(i*w,0,w-PropF(@"edge")*0.05,bars[i].val/1000.0);
        }
        
        
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
        
    } PopSurfaceForProjector();
}

@end
