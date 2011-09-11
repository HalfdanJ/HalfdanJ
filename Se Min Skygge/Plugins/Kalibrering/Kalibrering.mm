//
//  Kalibrering
//  SeMinSkygge
//  
//  ofxCocoaPlugins plugin
//  Created by Jonas Jongejan on 9/8/11.
//


#import "Kalibrering.h"
#import "ProjectorCalibrator.h"
#import "KinectCalibrator.h"

@implementation Kalibrering

-(void)initPlugin{
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.0 minValue:0.0 maxValue:127] named:@"calibratorIndex"];
    [self addProperty:[BoolProperty boolPropertyWithDefaultvalue:NO] named:@"go"];
    
    calibrators = [NSMutableArray array];
}

-(void)setup{
    Kinect * kinect = GetPlugin(Kinect);
    
    //0
    [calibrators addObject:[[ProjectorAlignment alloc] init]];
    
    //1
    KinectAlignment * kinectAlignment = [[KinectAlignment alloc] init];
    [kinectAlignment setKinect:[kinect getInstance:0]];    
    [calibrators addObject:kinectAlignment];
    
    //2
    kinectAlignment = [[KinectAlignment alloc] init];
    [kinectAlignment setKinect:[kinect getInstance:1]];    
    [calibrators addObject:kinectAlignment];
    
    
    //3
    ProjectorCalibrator * projectorCalibrator = [[ProjectorCalibrator alloc] init];
    [projectorCalibrator setKinect:[kinect getInstance:0]];    
    [projectorCalibrator setSurface:[GetPlugin(Keystoner) getSurface:@"Screen" viewNumber:0 projectorNumber:0]];
    [calibrators addObject:projectorCalibrator];
    
    
}

-(void)update:(NSDictionary *)drawingInformation{
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