//
//  KinectCalibrator.m
//  SeMinSkygge
//
//  Created by Jonas Jongejan on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KinectCalibrator.h"

@implementation KinectTest
@synthesize image1, image2, proj;

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
    image1->draw(0,0,320*0.5,240);
    image2->draw(320*0.5,0,320*0.5,240);
}

-(void)draw:(NSDictionary *)drawingInformation{
    image1->draw(0.5*proj,0,0.25,1);
    image2->draw(0.5*proj+0.25,0,0.25,1);
}



@end


@implementation KinectAlignment
@synthesize image, proj;

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
    image->draw(0,0,320,240);
}

-(void)draw:(NSDictionary *)drawingInformation{
    image->draw((0.5*proj)+0.1,0.3,0.3,0.4);
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
