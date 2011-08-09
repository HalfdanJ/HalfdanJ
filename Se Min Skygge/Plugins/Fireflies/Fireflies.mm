
#import "Fireflies.h"


@implementation Fireflies

-(void)initPlugin{
    
}

-(void)setup{
    [self assignMidiChannel:11]; 
    kinect = [GetPlugin(Kinect) getInstance:1];
    surface = [GetPlugin(Keystoner) getSurface:@"Screen" viewNumber:0 projectorNumber:0];
    numFlies = 100;
    
    noise = new ofxPerlin();

}

-(void)update:(NSDictionary *)drawingInformation{
    
    while(fireflies.size() < numFlies){
        Firefly newFly;
        newFly.pos = ofxVec3f(ofRandom(-1.0, 1.0),ofRandom(-1.0, 1.0),ofRandom(-1.0, 1.0));
        newFly.noise = noise;
        fireflies.push_back(newFly);
        
    }
    
    frameNum++;
    
    ofxVec3f v;
    for(int i=0;i<fireflies.size();i++){
        Firefly * a = &fireflies[i];
        for(int u=i+1;u<fireflies.size();u++){
            Firefly * b = &fireflies[u];
            
            v = a->pos - b->pos;
            float l = v.length();
            l = 0.1 - l;
            l *= 30;
            if(l > 0){
                v.normalize();
                
                
                a->a += v*l;
                b->a -= v*l;
            }
        }
    }
    
    for(int i=0;i<fireflies.size();i++){
        fireflies[i].update(1.0/ofGetFrameRate(), frameNum);
    }
                            
}

-(void)draw:(NSDictionary *)drawingInformation{
    ApplySurface(@"Screen"){
    //[GetPlugin(Keystoner)  applySurface:@"Screen" projectorNumber:1 viewNumber:ViewNumber];

    glPushMatrix();
    glTranslated(0.5, 0.5, 0.0);
    for(int i=0;i<fireflies.size();i++){
        fireflies[i].draw(1-appliedProjector);
    }
    glPopMatrix();
    
//    [GetPlugin(Keystoner)  popSurface];
    } PopSurface();
    
    
}

@end
