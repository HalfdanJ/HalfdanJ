//
//  ProjectorCalibrator.m
//  SeMinSkygge
//
//  Created by Se Min Skygge on 10/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProjectorCalibrator.h"


@implementation ProjectorTest

-(void)draw:(NSDictionary *)drawingInformation{
    ofFill();    

    for(int i=0;i<2;i++){
        float w = 0.5/4.0;

        ofSetColor(255,255,255);
        ofRect(0,0,w,ofGetHeight());

        ofSetColor(255,0,0);
        ofRect(w,0,w,ofGetHeight());

        ofSetColor(0,255,0);
        ofRect(w*2,0,w,ofGetHeight());

        ofSetColor(0,0,255);
        ofRect(w*3,0,w,ofGetHeight());

        glTranslated(0.5,0,0);
        
    }
}


@end

@implementation ProjectorAlignment

-(void)draw:(NSDictionary *)drawingInformation{
    ofSetColor(255,255,255);
    ofFill();
    ofRect(0,0,ofGetWidth(),ofGetHeight());
}


@end

@implementation ProjectorAutoCalibrator
@synthesize image, surface;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        bg = new ofxCvColorImage();
        bg->allocate(640,480);
        
        diff = new ofxCvColorImage();
        diff->allocate(640,480);
        
        now = new ofxCvColorImage();
        now->allocate(640,480);
        
        rect = NSMakeRect(0, 0, 0, 0);
        step = -1;
    }
    
    return self;
}

-(void) go{
    image->generateTexture();
    bg->setFromPixels(image->image_pixels, 640, 480);
    
    step = 0;
    corner = 0;
    timer = ofGetElapsedTimeMillis();
    bgNoise = 2;
    [self resetRect];
}

-(void)update:(NSDictionary *)drawingInformation{
    image->generateTexture();
    diff->setFromPixels(image->image_pixels, 640, 480);
    
    *diff -= *bg;
    
    int c=0;
    unsigned char * pixels = diff->getPixels();
    for(int i=0;i<640*480*3;i+=3){
        if(pixels[i] > 80){
            c ++;
        }
    }
    
    if(step >= 20){
        corners[corner] = ofxPoint2f(rect.origin.x + 0.5*rect.size.width, rect.origin.y + 0.5* rect.size.height);
        
        
        
        NSDictionary * ps = [[surface cornerPositions] objectAtIndex:corner];
		
		[ps setValue:[NSNumber numberWithFloat:(rect.origin.x + 0.5*rect.size.width)] forKey:@"x"];
		[ps setValue:[NSNumber numberWithFloat:( rect.origin.y + 0.5* rect.size.height)] forKey:@"y"];
		
		[surface recalculate];		
        
        
        corner ++;
        if(corner == 3){
            step = -1;
            rect = NSMakeRect(0, 0, 0, 0);

        //    bgNoise += 10;
        }
        step = 1;
        [self resetRect];
        

    }
    else if(step >= 0 && ofGetElapsedTimeMillis() > timer + 600){
        if(step == 0){
        } else {
            
            cout<<"C: "<<c<<" bg: "<<bgNoise<<" step "<<step<<endl;
            
            if(c > bgNoise){
                [self receivePositiveResult];
            } else {
                [self receiveNegativeResult];
            }
        }
        timer = ofGetElapsedTimeMillis();

        step ++;

    } else if(step == 0 && ofGetElapsedTimeMillis() > timer + 000){
        if(bgNoise < c)
            bgNoise = c+2;
    }
}

-(void)draw:(NSDictionary *)drawingInformation{
    if(step > 0){
        ofSetColor(255,255,255);
        glScaled(0.5,1,1);
        // glTranslated(1,0,0);
        ofRect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
        
      /*  ofSetColor(255,0,0);
        ofCircle(rect.origin.x + 0.5*rect.size.width, rect.origin.y + 0.5* rect.size.height,0.003);*/
    }
}

-(void)controlDraw:(NSDictionary *)drawingInformation{
    diff->draw(0,0,ofGetWidth(),ofGetHeight());
}

-(void) resetRect{
    rect = NSMakeRect(0.1, 0.15, 0.9, 0.7);
}


-(void) receivePositiveResult{
    widthHeightSwitcher = !widthHeightSwitcher;
    
    switch (corner) {
        case 0:
            if(widthHeightSwitcher){
                rect.size.width /= 2.0;
            } else {
                rect.size.height /= 2.0;
            }
            break;
        case 1:
            if(widthHeightSwitcher){
                rect.size.width /= 2.0;
                rect.origin.x += rect.size.width;
            } else {
                rect.size.height /= 2.0;
            }
            break;
        case 2:
            if(widthHeightSwitcher){
                rect.size.width /= 2.0;
                rect.origin.x += rect.size.width;

            } else {
                rect.size.height /= 2.0;
                rect.origin.y += rect.size.height;

            }
            break;
        case 3:
            if(widthHeightSwitcher){
                rect.size.width /= 2.0;
            } else {
                rect.size.height /= 2.0;
                rect.origin.y += rect.size.height;
            }
            break;
        default:
            break;
    }
    
}

-(void) receiveNegativeResult{
    //    
    switch (corner) {
        case 0:{
            if(widthHeightSwitcher){
                rect.origin.x += rect.size.width;
                // rect.size.width /= 2.0;
                
            } else {
                rect.origin.y += rect.size.height;
                //   rect.size.height /= 2.0;
            }
            break;
        }
        case 1:{
            if(widthHeightSwitcher){
                rect.origin.x -= rect.size.width;
                // rect.size.width /= 2.0;
                
            } else {
                rect.origin.y += rect.size.height;
                //   rect.size.height /= 2.0;
            }
            break;
        }
        case 2:{
            if(widthHeightSwitcher){
                rect.origin.x -= rect.size.width;
                // rect.size.width /= 2.0;
                
            } else {
                rect.origin.y -= rect.size.height;
                //   rect.size.height /= 2.0;
            }
            break;
        }
        case 3:{
            if(widthHeightSwitcher){
                rect.origin.x += rect.size.width;
                // rect.size.width /= 2.0;
                
            } else {
                rect.origin.y -= rect.size.height;
                //   rect.size.height /= 2.0;
            }
            break;
        }
        default:
            break;
    }
    

    
//    widthHeightSwitcher = !widthHeightSwitcher;
    
}

@end
