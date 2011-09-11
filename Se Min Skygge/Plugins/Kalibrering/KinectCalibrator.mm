//
//  KinectCalibrator.m
//  SeMinSkygge
//
//  Created by Jonas Jongejan on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KinectCalibrator.h"

@implementation KinectAlignment
@synthesize kinect;

- (id)init
{
    self = [super init];
    if (self) {
        font = new ofTrueTypeFont();
        font->loadFont("Helvetica.dfont",20, true, true);    
    }
    
    return self;
}


-(void)update:(NSDictionary *)drawingInformation{
    
}

-(void)controlDraw:(NSDictionary *)drawingInformation{
    if([kinect kinectConnected]){
        [kinect getColorGenerator]->draw(0,0,ofGetWidth(),ofGetHeight());
    } else {
        ofSetColor(0,0,0);
        font->drawString("Ingen forbindelse til kinect!",10,30);
    }
}

-(void)draw:(NSDictionary *)drawingInformation{
    
}



@end


@implementation KinectCalibrator
@synthesize kinect;

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
    
}
-(void)draw:(NSDictionary *)drawingInformation{
    
}
@end
