
#import "Fireflies.h"


@implementation Fireflies

-(void)initPlugin{
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:50.0] named:@"gravityForce"];   
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:5.0] named:@"perlinForce"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:5.0] named:@"perlinGridsize"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:5.0] named:@"perlinSpeed"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:5.0] named:@"opacitySpeed"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1] named:@"opacityNoise"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1] named:@"wortexForce"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.1 minValue:0.0 maxValue:1] named:@"damping"];

    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:100 minValue:0.0 maxValue:500] named:@"number"];  
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:0.0 maxValue:2] named:@"pushForce"];  
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:0.0 maxValue:2] named:@"pushDist"];  
} 


-(void)setup{
    [self assignMidiChannel:11]; 
    kinect = [GetPlugin(Kinect) getInstance:1];
    surface = [GetPlugin(Keystoner) getSurface:@"Screen" viewNumber:0 projectorNumber:0];
    numFlies = 100;
    
    noise = new ofxPerlin();
    img = new ofImage();
    img->loadImage("firefly.png");
    
}

-(void)update:(NSDictionary *)drawingInformation{
    gravityForce = PropF(@"gravityForce");
    perlinForce = PropF(@"perlinForce");
    perlinGridsize = PropF(@"perlinGridsize");
    perlinSpeed = PropF(@"perlinSpeed");
    opacitySpeed = PropF(@"opacitySpeed");
    opacityNoise = PropF(@"opacityNoise"); 
    wortexForce = PropF(@"wortexForce");
    damping = PropF(@"damping");
    
    numFlies = PropI(@"number");
    
    while(fireflies.size() < numFlies){
        Firefly newFly;
        newFly.pos = ofxVec3f(ofRandom(-1.0, 1.0),ofRandom(-1.0, 1.0),ofRandom(-1.0, 1.0));
        newFly.noise = noise;
        newFly.img = img;
        newFly.i = fireflies.size();
        newFly.gravityForce = &gravityForce;
        newFly.perlinForce = &perlinForce;
        newFly.perlinGridsize = &perlinGridsize;
        newFly.perlinSpeed = &perlinSpeed;
        newFly.opacitySpeed = &opacitySpeed;
        newFly.opacityNoise = &opacityNoise;  
        newFly.wortexForce = &wortexForce;
        newFly.damping = &damping;
        
        fireflies.push_back(newFly);
        
    }
    
    while(fireflies.size() > numFlies){
        fireflies.pop_back();
    }
    
    frameNum++;
    
    float pushDist = PropF(@"pushDist");
    float pushForce = PropF(@"pushForce");
    if(frameNum > 20 && ofGetFrameRate() > 10){
        
        ofxVec3f v;
        for(int i=0;i<fireflies.size();i++){
            Firefly * a = &fireflies[i];
            for(int u=i+1;u<fireflies.size();u++){
                Firefly * b = &fireflies[u];
                
                v = a->pos - b->pos;
                float l = v.length();
                l = pushDist*0.1  - l;
                l *= pushForce*30.0;
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
    
}

-(void)draw:(NSDictionary *)drawingInformation{
    ApplySurface(@"Screen"){
        //[GetPlugin(Keystoner)  applySurface:@"Screen" projectorNumber:1 viewNumber:ViewNumber];
        
        glPushMatrix();
        glTranslated(Aspect(@"Screen",0)*0.5, 0.5, 0.0);
        for(int i=0;i<fireflies.size();i++){
            fireflies[i].draw(1-appliedProjector);
        }
        glPopMatrix();
        
        //    [GetPlugin(Keystoner)  popSurface];
    } PopSurface();
    
    
}

@end
