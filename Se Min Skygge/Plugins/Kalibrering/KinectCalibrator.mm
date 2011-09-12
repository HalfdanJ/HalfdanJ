//
//  KinectCalibrator.m
//  SeMinSkygge
//
//  Created by Jonas Jongejan on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KinectCalibrator.h"

@implementation KinectAlignment
@synthesize image;

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

   // image1.update();
/*    if([otherKinect irEnabled]){
        [otherKinect setIrEnabled:NO];
    }
    else if(![kinect irEnabled] || ![kinect colorEnabled]){
        [kinect setColorEnabled:YES];

        [kinect setIrEnabled:YES];
    }*/
}

-(void)controlDraw:(NSDictionary *)drawingInformation{
    image->draw(0,0,320,240);

/*    if([kinect kinectConnected]){

        [kinect getColorGenerator]->draw(0,0,ofGetWidth(),ofGetHeight());
    } else if([kinect irEnabled]){
        ofSetColor(0,0,0);
        font->drawString("Opretter forbindelse...",10,30);
    }   else {
        ofSetColor(0,0,0);
        font->drawString("Ingen forbindelse til kinect!",10,30);
    }*/
}

-(void)draw:(NSDictionary *)drawingInformation{
   /* if([kinect kinectConnected]){        
        [kinect getColorGenerator]->draw(0,0,0.5,1);
    } else if([kinect irEnabled]){
        ofSetColor(255,255,255);
        glScaled(1.0/2048, 1.0/768,1);
        font->drawString("Opretter forbindelse...",300,300);
    }   else {
        ofSetColor(255,255,255);
        glScaled(1.0/2048, 1.0/768,1);
        font->drawString("Ingen forbindelse til kinect!",10,30);
    }*/
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
