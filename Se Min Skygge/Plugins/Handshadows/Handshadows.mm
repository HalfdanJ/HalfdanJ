//
//  Handshadows
//  SeMinSkygge
//  
//  ofxCocoaPlugins plugin
//  Created by Se Min Skygge on 20/08/11.
//


#import "Handshadows.h"
#import "Keystoner.h"
#import "InteractiveWall.h"

@implementation Handshadows

-(void)initPlugin{
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1.0] named:@"marginTop"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1.0] named:@"marginRight"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1.0] named:@"marginLeft"];
    
    
    for(int i=0;i<NUM_BOXES;i++){
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1.9] named:[NSString stringWithFormat:@"box%iPosLeft",i]];
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1.9] named:[NSString stringWithFormat:@"box%iPosRight",i]];
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:[NSString stringWithFormat:@"box%iPosBottom",i]];
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:[NSString stringWithFormat:@"box%iPosTop",i]];
        
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:16] named:[NSString stringWithFormat:@"box%iModeTop",i]];
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:16] named:[NSString stringWithFormat:@"box%iModeBottom",i]];
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:16] named:[NSString stringWithFormat:@"box%iModeLeft",i]];
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:16] named:[NSString stringWithFormat:@"box%iModeRight",i]];
        
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:1 maxValue:10] named:@"speed"];
        [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:0 maxValue:1] named:@"maxDist"];
        [self addProperty:[BoolProperty boolPropertyWithDefaultvalue:NO] named:@"drawDebug"];
        
    }
}

-(void)setup{
    for(int i=0;i<NUM_BOXES;i++){
        Box nBox;
        boxes.push_back(nBox);
    }
    
    kinect = [GetPlugin(Kinect) getInstance:1];
    [self assignMidiChannel:12]; 
        
    fbo = new ofxFBOTexture();
    fbo->allocate(1024, 540);
}

-(void)update:(NSDictionary *)drawingInformation{
    for(int i=0;i<PropI(@"speed");i++){
        for(int j=0;j<NUM_BOXES;j++){        
            boxes[j].sides[0].filter(PropF(([NSString stringWithFormat:@"box%iPosTop",j])));
            boxes[j].sides[1].filter(PropF(([NSString stringWithFormat:@"box%iPosRight",j])));
            boxes[j].sides[2].filter(PropF(([NSString stringWithFormat:@"box%iPosBottom",j])));
            boxes[j].sides[3].filter(PropF(([NSString stringWithFormat:@"box%iPosLeft",j])));
        }
    }
    
    float aspect = Aspect(@"Screen",1);
    
    InteractiveWall * wall = GetPlugin(InteractiveWall);
    
    vector<ofxPoint3f> p = [kinect getPointsInBoxXMin:0.1 xMax:Aspect(@"Screen",1)-0.1 yMin:0.1 yMax:0.9 zMin:-1000 zMax:-[[[wall properties] valueForKey:@"screenDist"] floatValue] res:[[[wall properties] valueForKey:@"kinectRes"] floatValue] ];
    
    float xMin = -1;
    float xMax = -1;
    float yMin = -1;
    float yMax = -1;
    
    for(int i=0;i<p.size();i++){
        ofxPoint3f kinectP = [kinect convertWorldToKinect:[kinect convertSurfaceToWorld:p[i]]];        
        ofxPoint2f warped = [kinect coordWarper]->transform(kinectP.x/640.0, kinectP.y/480.0);
        
        if(xMin == -1 || xMin > warped.x)
            xMin = warped.x;
        if(xMax == -1 || xMax < warped.x)
            xMax = warped.x;
        if(yMin == -1 || yMin  > warped.y)
            yMin  = warped.y;
        if(yMax == -1 || yMax < warped.y)
            yMax = warped.y;
    }
    
    xMin *= aspect;
   // yMin *= aspect;
    xMax *= aspect;
   // yMax *= aspect;
    
    int modes[4];
    
    for(int j=0;j<NUM_BOXES;j++){
        modes[0] = PropI(([NSString stringWithFormat:@"box%iModeTop",j]));
        modes[2] = PropI(([NSString stringWithFormat:@"box%iModeBottom",j]));
        modes[3] = PropI(([NSString stringWithFormat:@"box%iModeLeft",j]));
        modes[1] = PropI(([NSString stringWithFormat:@"box%iModeRight",j]));
        
        
        
        //Grow
        if(modes[0] == 1 && boxes[j].sides[0].value() > yMin && fabs(boxes[j].sides[0].value() - yMin) < PropF(@"maxDist")){
            [Prop(([NSString stringWithFormat:@"box%iPosTop",j])) setFloatValue:yMin-PropF(@"marginTop")];
            //boxes[j].sides[0].filter(yMin);     
        }
        if(modes[1] == 1 && boxes[j].sides[1].value() < xMax && fabs(boxes[j].sides[1].value() - xMax) < PropF(@"maxDist")){
            [Prop(([NSString stringWithFormat:@"box%iPosRight",j])) setFloatValue:xMax+PropF(@"marginRight")];
            //boxes[j].sides[1].filter(xMax);     
        }
        if(modes[2] == 1 && boxes[j].sides[2].value() < yMax && fabs(boxes[j].sides[2].value() - yMax) < PropF(@"maxDist")){
            [Prop(([NSString stringWithFormat:@"box%iPosBottom",j])) setFloatValue:yMax];
            //boxes[j].sides[2].filter(yMax);     
        }
        if(modes[3] == 1 && boxes[j].sides[3].value() > xMin && fabs(boxes[j].sides[3].value() - xMin) < PropF(@"maxDist")){
            [Prop(([NSString stringWithFormat:@"box%iPosLeft",j])) setFloatValue:xMin-PropF(@"marginLeft")];
            //boxes[j].sides[3].filter(xMin);     
        }
        
        //Snap
        if(modes[0] == 2  && fabs(boxes[j].sides[0].value() - yMin) < PropF(@"maxDist")){
            [Prop(([NSString stringWithFormat:@"box%iPosTop",j])) setFloatValue:yMin-PropF(@"marginTop")];
            //boxes[j].sides[0].filter(yMin);     
        }
        if(modes[1] == 2 && fabs(boxes[j].sides[1].value() - xMax) < PropF(@"maxDist")){
            [Prop(([NSString stringWithFormat:@"box%iPosRight",j])) setFloatValue:xMax+PropF(@"marginRight")];
            //boxes[j].sides[1].filter(xMax);     
        }
        if(modes[2] == 2 && fabs(boxes[j].sides[2].value() - yMax) < PropF(@"maxDist")){
            [Prop(([NSString stringWithFormat:@"box%iPosBottom",j])) setFloatValue:yMax];
            //boxes[j].sides[2].filter(yMax);     
        }
        if(modes[3] == 2 && fabs(boxes[j].sides[3].value() - xMin) < PropF(@"maxDist")){
            [Prop(([NSString stringWithFormat:@"box%iPosLeft",j])) setFloatValue:xMin-PropF(@"marginLeft")];
            //boxes[j].sides[3].filter(xMin);     
        }        
    }
    
    
}

-(void)draw:(NSDictionary *)drawingInformation{
    ofFill();
    ofEnableAlphaBlending();
    
    fbo->begin();
    ofSetColor(0,0,0);
    ofRect(0,0,1,1);
    float w = Aspect(@"Screen",1);
        for(int i=0;i<NUM_BOXES;i++){
            ofSetColor(255,255,255);
            
            float l = boxes[i].sides[3].value()/w;
            float t = boxes[i].sides[0].value();
            float r = boxes[i].sides[1].value()/w;
            float b = boxes[i].sides[2].value();
            
            if(l < r && t < b){
                ofRect(l,t,r-l,b-t);
            }
        }
    
    fbo->end();
    
    ApplySurfaceForProjector(@"Screen",1){
        glBlendFunc(GL_ONE_MINUS_DST_COLOR, GL_ZERO);
        fbo->draw(0,0,Aspect(@"Screen",1), 1);
        
        if(PropB(@"drawDebug")){
            ofSetColor(255,0,0);
            InteractiveWall * wall = GetPlugin(InteractiveWall);
            
            vector<ofxPoint3f> p = [kinect getPointsInBoxXMin:0 xMax:Aspect(@"Screen",1) yMin:0 yMax:1 zMin:-1000 zMax:-[[[wall properties] valueForKey:@"screenDist"] floatValue] res:[[[wall properties] valueForKey:@"kinectRes"] floatValue] ];
            
            for(int i=0;i<p.size();i++){
                
                ofxPoint3f kinectP = [kinect convertWorldToKinect:[kinect convertSurfaceToWorld:p[i]]];        
                ofxPoint2f warped = [kinect coordWarper]->transform(kinectP.x/640.0, kinectP.y/480.0);
                
                /*ofSetColor(255,0,0);
                 ofRect(p[i].x,p[i].y,0.01,0.01);
                 */
                ofSetColor(0,255,0);
                ofRect(warped.x*Aspect(@"Screen",1),warped.y,0.01,0.01);
            }
        }
        
    }PopSurfaceForProjector();
}

@end