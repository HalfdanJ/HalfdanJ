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
    
    [self addProperty:[BoolProperty boolPropertyWithDefaultvalue:NO] named:@"colorCamera"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:5 minValue:0.0 maxValue:50] named:@"kinectThreshold"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:7 minValue:0.0 maxValue:50] named:@"kinectThreshold2"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0.0 maxValue:10] named:@"kinectBlur"];
    
    [self assignMidiChannel:13];
    calibrators = [NSMutableArray array];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if(object == Prop(@"calibratorIndex")){
        if([calibrators count] > PropI(@"calibratorIndex") && [[calibrators objectAtIndex:PropI(@"calibratorIndex")] respondsToSelector:@selector(reset)]){
            [[calibrators objectAtIndex:PropI(@"calibratorIndex")] reset];
            
        }
        
    }
}

-(void)setup{
    
    [Prop(@"Enabled") setBoolValue:NO];
    [Prop(@"calibratorIndex") setIntValue:0];        
    [Prop(@"colorCamera") setBoolValue:NO];
    
    firstRun = NO;
    
    
    
    Kinect * kinect = GetPlugin(Kinect);
    kinect1 = [kinect getInstance:0];
    kinect2 = [kinect getInstance:1];
    
    
    
    image1 = new ofxImageGenerator();  
    
    image2 = new ofxImageGenerator();
    
    
    //0
    [calibrators addObject:[[ProjectorTest alloc] init]];
    
    //1
    KinectTest * kinectAlignment = [[KinectTest alloc] init];
    [kinectAlignment setImage1:image1];            
    [kinectAlignment setImage2:image2];            
    [kinectAlignment setProj:0];            
    [calibrators addObject:kinectAlignment];
    
    
    //2
    [calibrators addObject:[[ProjectorAlignment alloc] init]];
    
    //3
    KinectAlignment * kinectAlign = [[KinectAlignment alloc] init];
    [kinectAlign setProj:0];
    [kinectAlign setImage:image1];
    [kinectAlign setKinect:kinect1];
    [calibrators addObject:kinectAlign];
    
    //4
    kinectAlign = [[KinectAlignment alloc] init];
    [kinectAlign setProj:1];
    [kinectAlign setImage:image2];
    [kinectAlign setKinect:kinect2];
    [kinectAlign setDepth:YES];
    [calibrators addObject:kinectAlign];
    
    //5
    [calibrators addObject:kinectAlign];
    
    
    //6
    KinectCalibrator * kinectCalib = [[KinectCalibrator alloc] init];
    [kinectCalib setKinect:kinect1];
    [kinectCalib setThreshold:Prop(@"kinectThreshold")];
    [kinectCalib setProj:1];
    [kinectCalib setBlur:Prop(@"kinectBlur")];
    [calibrators addObject:kinectCalib];
    
    //7
    kinectCalib = [[KinectCalibrator alloc] init];
    [kinectCalib setKinect:kinect2];
    [kinectCalib setThreshold:Prop(@"kinectThreshold2")];
    [kinectCalib setBlur:Prop(@"kinectBlur")];
    [kinectCalib setDepth:YES];
    [kinectCalib setProj:0];
    [calibrators addObject:kinectCalib];    
    
    
    //8
    Tests * test = [[Tests alloc] init];
    [test setText:@"Front kinect test"];
    [calibrators addObject:test];
    
    //9
    test = [[Tests alloc] init];
    [test setText:@"Bag kinect test"];
    [calibrators addObject:test];
}

-(void)update:(NSDictionary *)drawingInformation{
    if(!firstRun && PropB(@"colorCamera")){
        context = new ofxOpenNIContext();
        context->setup();
        
        image1->deviceInfoChar =  [[kinect1 deviceChar] cStringUsingEncoding:NSUTF8StringEncoding];
        image1->setup(context);
        
        image2->deviceInfoChar =  [[kinect2 deviceChar] cStringUsingEncoding:NSUTF8StringEncoding];
        image2->setup(context);
        
        
        /*   //3
         ProjectorAutoCalibrator * projectorCalibrator = [[ProjectorAutoCalibrator alloc] init];
         [projectorCalibrator setImage:image2];    
         [projectorCalibrator setSurface:[GetPlugin(Keystoner) getSurface:@"Screen" viewNumber:0 projectorNumber:0]];
         [calibrators addObject:projectorCalibrator];
         */ 
        
        
        firstRun = YES;    
    } else if(firstRun && !PropB(@"colorCamera")){
        firstRun = NO;
        image1->connected = false;
        image2->connected = false;
        context->getXnContext().Shutdown();
    }
    
    if(PropB(@"colorCamera")){
        context->update();
    }
    
    
    if(PropB(@"go")){
        [Prop(@"go") setBoolValue:NO];
        
        if([calibrators count] > PropI(@"calibratorIndex") && [[calibrators objectAtIndex:PropI(@"calibratorIndex")] respondsToSelector:@selector(go)])
            [[calibrators objectAtIndex:PropI(@"calibratorIndex")] go];
    }
    
    if([calibrators count] > PropI(@"calibratorIndex") && [[calibrators objectAtIndex:PropI(@"calibratorIndex")] respondsToSelector:@selector(update:)])
        [[calibrators objectAtIndex:PropI(@"calibratorIndex")] update:drawingInformation];
}

-(void)controlDraw:(NSDictionary *)drawingInformation{
    if([calibrators count] > PropI(@"calibratorIndex") && [[calibrators objectAtIndex:PropI(@"calibratorIndex")] respondsToSelector:@selector(controlDraw:)]){
        [[calibrators objectAtIndex:PropI(@"calibratorIndex")] controlDraw:
         drawingInformation];
        if([controlGlView isHidden]){
            [controlGlView setHidden:NO];
        }
        
    } else {
        if(![controlGlView isHidden]){
            [controlGlView setHidden:YES];
        }
    }
} 

-(void)draw:(NSDictionary *)drawingInformation{
    if([calibrators count] > PropI(@"calibratorIndex") && [[calibrators objectAtIndex:PropI(@"calibratorIndex")] respondsToSelector:@selector(draw:)])
        [[calibrators objectAtIndex:PropI(@"calibratorIndex")] draw:drawingInformation];
    
    
}

@end