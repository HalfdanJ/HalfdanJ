//
//  Tapet
//  SeMinSkygge
//  
//  ofxCocoaPlugins plugin
//  Created by Se Min Skygge on 31/08/11.
//


#import "Tapet.h"
#import "RenderEngine.h"
#import "Keystoner.h"

@implementation Tapet

-(void)initPlugin{
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"tapetBack"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"tapetFront"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"patBack"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"patFront"];
    
    [self assignMidiChannel:8];
}

-(void)setup{
    NSString * path = [NSString stringWithFormat:@"%@/Tapet/TapetPlain.png",[GetPlugin(RenderEngine) assetDir]];
    NSString * path2 = [NSString stringWithFormat:@"%@/Tapet/Patinering.png",[GetPlugin(RenderEngine) assetDir]];

    tapetImage = new ofImage();
    patImage = new ofImage();

    tapetImage->loadImage([path cStringUsingEncoding:NSUTF8StringEncoding]);
    patImage->loadImage([path2 cStringUsingEncoding:NSUTF8StringEncoding]);

}

-(void)update:(NSDictionary *)drawingInformation{
    
}

-(void)draw:(NSDictionary *)drawingInformation{
    ApplySurface(@"Screen");{
        if(appliedProjector == 0){
            ofSetColor(255,255,255,255.0*PropF(@"tapetFront"));
            tapetImage->draw(0,0,Aspect(@"Screen",1),1);

            ofSetColor(255,255,255,255.0*PropF(@"patFront"));
            patImage->draw(0,0,Aspect(@"Screen",1),1);
        } else {
            ofSetColor(255,255,255,255.0*PropF(@"tapetBack"));
            tapetImage->draw(0,0,Aspect(@"Screen",1),1);
            
            ofSetColor(255,255,255,255.0*PropF(@"patBack"));
            patImage->draw(0,0,Aspect(@"Screen",1),1);  
        }
        
    } PopSurface();
}

@end