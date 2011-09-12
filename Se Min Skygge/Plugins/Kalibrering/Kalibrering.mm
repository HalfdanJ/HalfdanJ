//
//  Kalibrering
//  SeMinSkygge
//  
//  ofxCocoaPlugins plugin
//  Created by Jonas Jongejan on 9/8/11.
//


#import "Kalibrering.h"
#import "ProjectorCalibrator.h"

@implementation Kalibrering

-(void)initPlugin{
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:127] named:@"calibratorIndex"];
    [self addProperty:[BoolProperty boolPropertyWithDefaultvalue:NO] named:@"go"];
    
    calibrators = [NSMutableArray array];
}

-(void)setup{
    
  //  [Prop(@"Enabled") setBoolValue:NO];
 //   [Prop(@"calibratorIndex") setIntValue:0];    
    

    firstRun = NO;
}

-(void)update:(NSDictionary *)drawingInformation{
    if(!firstRun){
        Kinect * kinect = GetPlugin(Kinect);
        kinect1 = [kinect getInstance:0];
        kinect2 = [kinect getInstance:1];
        
        context = new ofxOpenNIContext();
        context->setup();
        
        image1 = new ofxImageGenerator();
        image1->deviceInfoChar =  [[kinect1 deviceChar] cStringUsingEncoding:NSUTF8StringEncoding];
        image1->setup(context);
        
        image2 = new ofxImageGenerator();
        image2->deviceInfoChar =  [[kinect2 deviceChar] cStringUsingEncoding:NSUTF8StringEncoding];
        image2->setup(context);
    
        
        
        //0
        [calibrators addObject:[[ProjectorAlignment alloc] init]];
        
        //1
        KinectAlignment * kinectAlignment = [[KinectAlignment alloc] init];
        [kinectAlignment setImage:image1];            
        [calibrators addObject:kinectAlignment];
        
        //2
        kinectAlignment = [[KinectAlignment alloc] init];
        [kinectAlignment setImage:image2];            
        [calibrators addObject:kinectAlignment];
        
        //3
        ProjectorCalibrator * projectorCalibrator = [[ProjectorCalibrator alloc] init];
        [projectorCalibrator setImage:image2];    
        [projectorCalibrator setSurface:[GetPlugin(Keystoner) getSurface:@"Screen" viewNumber:0 projectorNumber:0]];
        [calibrators addObject:projectorCalibrator];
        
        
        
        firstRun = YES;    
    }
    
    context->update();
    
    
    if(PropB(@"go")){
        [Prop(@"go") setBoolValue:NO];
        
        if([calibrators count] > PropI(@"calibratorIndex") && [[calibrators objectAtIndex:PropI(@"calibratorIndex")] respondsToSelector:@selector(go)])
            [[calibrators objectAtIndex:PropI(@"calibratorIndex")] go];
    }
    
    if([calibrators count] > PropI(@"calibratorIndex") && [[calibrators objectAtIndex:PropI(@"calibratorIndex")] respondsToSelector:@selector(update:)])
        [[calibrators objectAtIndex:PropI(@"calibratorIndex")] update:drawingInformation];
}

-(void)controlDraw:(NSDictionary *)drawingInformation{
    if([calibrators count] > PropI(@"calibratorIndex") && [[calibrators objectAtIndex:PropI(@"calibratorIndex")] respondsToSelector:@selector(controlDraw:)])
        [[calibrators objectAtIndex:PropI(@"calibratorIndex")] controlDraw:drawingInformation];
} 

-(void)draw:(NSDictionary *)drawingInformation{
    if([calibrators count] > PropI(@"calibratorIndex") && [[calibrators objectAtIndex:PropI(@"calibratorIndex")] respondsToSelector:@selector(draw:)])
        [[calibrators objectAtIndex:PropI(@"calibratorIndex")] draw:drawingInformation];
    
    
}

@end