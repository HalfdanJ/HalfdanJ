//
//  ProjectorCalibrator.m
//  SeMinSkygge
//
//  Created by Se Min Skygge on 10/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProjectorCalibrator.h"

@implementation ProjectorAlignment

-(void)draw:(NSDictionary *)drawingInformation{
    ofSetColor(255,255,255);
    ofFill();
    ofRect(0,0,ofGetWidth(),ofGetHeight());
}


@end

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

-(void) resetRect{
    rect = NSMakeRect(0, 0, 1, 1);
}


-(void) receivePositiveResult{
    widthHeightSwitcher = !widthHeightSwitcher;
    
    if(widthHeightSwitcher){
        rect.size.width /= 2.0;
    } else {
        rect.size.height /= 2.0;
    }
}

-(void) receiveNegativeResult{
    widthHeightSwitcher = !widthHeightSwitcher;

    if(widthHeightSwitcher){
        rect.origin.x += rect.size.width/2.0;
    } else {
        rect.origin.y += rect.size.height/2.0;
    }
    
}

@end
