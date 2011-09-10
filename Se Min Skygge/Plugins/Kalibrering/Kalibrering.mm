//
//  Kalibrering
//  SeMinSkygge
//  
//  ofxCocoaPlugins plugin
//  Created by Jonas Jongejan on 9/8/11.
//


#import "Kalibrering.h"
#import "Kinect.h"

@implementation Kalibrering

-(void)initPlugin{
    
}

-(void)setup{
     Kinect * kinect = GetPlugin(Kinect);
    
    projCalib[0] = [[ProjectorCalibrator alloc] init];
//    [projCalib[0] setSurface:Surface(@"Screen",0)];
    [projCalib[0] setKinect:[kinect getInstance:0]];
    
}

-(void)update:(NSDictionary *)drawingInformation{
    [projCalib[0] update:drawingInformation];
}

-(void)controlDraw:(NSDictionary *)drawingInformation{
    [projCalib[0] controlDraw:drawingInformation];
} 

-(void)draw:(NSDictionary *)drawingInformation{
    ofSetColor(255,255,255);
    
    
}

@end