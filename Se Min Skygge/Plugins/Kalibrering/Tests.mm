//
//  Tests.m
//  SeMinSkygge
//
//  Created by Se Min Skygge on 15/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Tests.h"

@implementation Tests
@synthesize text;

- (id)init
{
    self = [super init];
    if (self) {
        font = new ofTrueTypeFont();
        font->loadFont("Helvetica.dfont",20, true, true);    
    }
    
    return self;
}

-(void)draw:(NSDictionary *)drawingInformation{
    glScaled(1.0/100.0, 1.0/100.0, 1.0);
    ofSetColor(255,255,255);
    font->drawString([text cStringUsingEncoding:NSUTF8StringEncoding], 0.1, 0.5);
}

@end
