//
//  ProjectorCalibrator.m
//  SeMinSkygge
//
//  Created by Se Min Skygge on 10/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProjectorCalibrator.h"

@implementation ProjectorCalibrator
@synthesize kinect, surface;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)update:(NSDictionary *)drawingInformation{
    
}

-(void)controlDraw:(NSDictionary *)drawingInformation{
    if([kinect kinectConnected]){
        [kinect getColorGenerator]->draw(0,0,ofGetWidth(),ofGetHeight());
    }
    
}

@end
