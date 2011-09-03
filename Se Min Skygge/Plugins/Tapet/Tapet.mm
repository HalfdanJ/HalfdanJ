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
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"maskFront"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"maskBack"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"whiteFront"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"whiteBack"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"tintR"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"tintG"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:1.0] named:@"tintB"];
    [self assignMidiChannel:8];
}

-(void)setup{
    NSString * path = [NSString stringWithFormat:@"%@/Tapet/TapetPlain.png",[GetPlugin(RenderEngine) assetDir]];
    NSString * path2 = [NSString stringWithFormat:@"%@/Tapet/Patinering.png",[GetPlugin(RenderEngine) assetDir]];
    NSString * path3 = [NSString stringWithFormat:@"%@/Tapet/TapetMask.png",[GetPlugin(RenderEngine) assetDir]];

    tapetImage = new ofImage();
    patImage = new ofImage();
    maskImage = new ofImage();

    tapetImage->loadImage([path cStringUsingEncoding:NSUTF8StringEncoding]);
    patImage->loadImage([path2 cStringUsingEncoding:NSUTF8StringEncoding]);
    maskImage->loadImage([path3 cStringUsingEncoding:NSUTF8StringEncoding]);

}

-(void)update:(NSDictionary *)drawingInformation{
    
}

-(void)draw:(NSDictionary *)drawingInformation{
    float r = PropF(@"tintR")*255.0;
    float g = PropF(@"tintG")*255.0;
    float b = PropF(@"tintB")*255.0;
    ofEnableAlphaBlending();
    ofFill();
    ApplySurface(@"Screen");{
        if(appliedProjector == 0){
            ofSetColor(r,g,b,255.0*PropF(@"tapetFront"));
            tapetImage->draw(0,0,Aspect(@"Screen",1),1);

            ofSetColor(r,g,b,255.0*PropF(@"patFront"));
            patImage->draw(0,0,Aspect(@"Screen",1),1);
            
            float white = PropF(@"whiteFront");
            if(white > 0){
                ofSetColor(r,g,b,white*255.0);
                ofRect(0,0,Aspect(@"Screen",1),1);
            }
            
            float mask = PropF(@"maskFront");
            if(mask > 0){
                glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_COLOR);
                ofSetColor(mask*r,mask*g,mask*b);
                maskImage->draw(0,0,Aspect(@"Screen",1),1);
            }
        } else {
            ofSetColor(r,g,b,255.0*PropF(@"tapetBack"));
            tapetImage->draw(0,0,Aspect(@"Screen",1),1);
            
            ofSetColor(r,g,b,255.0*PropF(@"patBack"));
            patImage->draw(0,0,Aspect(@"Screen",1),1);  

            float white = PropF(@"whiteBack");
            if(white > 0){
                ofSetColor(r,g,b,white*255.0);
                ofRect(0,0,Aspect(@"Screen",1),1);
            }

            float mask = PropF(@"maskBack");
            if(mask > 0){
                glBlendFunc(GL_ZERO, GL_SRC_COLOR);
                ofSetColor(mask*r,mask*g,mask*b);
                maskImage->draw(0,0,Aspect(@"Screen",1),1);
            }

        }
        
    } PopSurface();
}

@end