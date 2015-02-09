//
//  KinectCalibrator.m
//  SeMinSkygge
//
//  Created by Jonas Jongejan on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KinectCalibrator.h"
#import "TextureGrid.h"

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
@synthesize image, proj, kinect, depth;

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
    ofBackground(0,0,0);
    if(!depth){
        ofxIRGenerator * img = [kinect getIRGenerator];
        img->draw(0,0,320,240);
    } else {
        ofxDepthGenerator * img = [kinect getDepthGenerator];
        img->draw(0,0,320,240);        
    }
}

-(void)draw:(NSDictionary *)drawingInformation{
    if(!depth){
        ofxIRGenerator * img = [kinect getIRGenerator];
        img->draw((0.5*proj)+0.1,0.3,0.3,0.4);
        ofSetColor(0,255,0,100);
        
        ofNoFill();
        ofRect((0.5*proj)+0.1,0.3,0.3,0.4);
        ofFill();
    } else {
        ofxDepthGenerator * img = [kinect getDepthGenerator];
        img->draw((0.5*proj)+0.1,0.3,0.3,0.4);
        
        ofSetColor(0,255,0,100);        
        ofNoFill();
        ofRect((0.5*proj)+0.1,0.3,0.3,0.4);
        ofFill();
    }
    
    /*if(proj == 0){
        glScaled(1.0/400.0, 1.0/200.0, 1.0);
        ofSetColor(255,255,255);
        font->drawString("Front", 0.4, 1);
    } else {
        glScaled(1.0/400.0, 1.0/200.0, 1.0);
        ofSetColor(255,255,255);
        font->drawString("Back", 0.4, 1);        
    }*/
}
@end


@implementation KinectCalibrator
@synthesize kinect, threshold, proj, blur, depth;

- (id)init
{
    self = [super init];
    if (self) {
        bg = new ofxCvGrayscaleImage();
        bg->allocate(640,480);
        
        diff = new ofxCvGrayscaleImage();
        diff->allocate(640,480);
        
        now = new ofxCvGrayscaleImage();
        now->allocate(640,480);
        
        tracker = new ofxCvContourFinder();
        
        step = 0;
        
    }
    
    return self;
}

-(void) go{
    step = 0;
    if(step == 0){
        *bg = *now;
        corner = 0;
        timer = 0;
        
        if(depth){
            ofxDepthGenerator * image = [kinect getDepthGenerator];
            xn::DepthMetaData dmd;
            image->getXnDepthGenerator().GetMetaData(dmd);	
            const XnDepthPixel* _depth = dmd.Data();            
            memcpy(depthBg, _depth, 640*480);
        }
    }
    
    step ++;
}


-(void)update:(NSDictionary *)drawingInformation{
    // if(step > 0){
    if(!depth){
        ofxIRGenerator * image = [kinect getIRGenerator];
        image->generateTexture();
        if(image->connected){
            now->setFromPixels(image->image_pixels, 640, 480);        
        }
        int _blur = (int)([blur intValue]);
        if(_blur % 2 == 0) _blur += 1;        
        now->blur(_blur);        
        diff->absDiff(*bg, *now);
        diff->threshold( (int)([threshold intValue]) );
        
    } else {
        //Depth
        ofxDepthGenerator * image = [kinect getDepthGenerator];
        xn::DepthMetaData dmd;
        image->getXnDepthGenerator().GetMetaData(dmd);	
        
        float max_depth = image->getXnDepthGenerator().GetDeviceMaxDepth();		
        
        const XnDepthPixel* _depth = dmd.Data();
        XN_ASSERT(depth);
        
        
        for (XnUInt16 y = dmd.YOffset(); y < dmd.YRes() + dmd.YOffset(); y++) {
            unsigned char * texture = (unsigned char*)depth_pixels + y * dmd.XRes() + dmd.XOffset();
            for (XnUInt16 x = 0; x < dmd.XRes(); x++, _depth++, texture++) {
                texture[0] = *_depth / max_depth*255;
            }
        }
        
        now->setFromPixels(depth_pixels, 640, 480);        
        diff->absDiff(*bg, *now);
        diff->threshold( (int)([threshold intValue]) );
        
    }
    
    
    tracker->findContours(*diff, 100*100, 640*480, 1, NO);
    
    if(tracker->nBlobs > 0){
        personFound = YES;
        
        ofxPoint2f pGoal = ofxPoint2f();
        ofxCvBlob * blob = &tracker->blobs[0];
        if(!depth){
            if(corner == 0){
                for(int i=0;i<blob->nPts;i++){
                    if(pGoal == ofxPoint2f() || (pGoal.x > blob->pts[i].x/640.0 && blob->pts[i].y < 240)){
                        pGoal = ofxPoint2f(blob->pts[i].x/640.0, blob->pts[i].y/480.0);            
                    }
                }           
            }
            if(corner == 1){
                for(int i=0;i<blob->nPts;i++){
                    if(pGoal == ofxPoint2f() || (pGoal.x < blob->pts[i].x/640.0 && blob->pts[i].y < 240)){
                        pGoal = ofxPoint2f(blob->pts[i].x/640.0, blob->pts[i].y/480.0);            
                    }
                }           
            }
            if(corner == 2){
                for(int i=0;i<blob->nPts;i++){
                    if(pGoal == ofxPoint2f() || (pGoal.x < blob->pts[i].x/640.0 && blob->pts[i].y > 240)){
                        pGoal = ofxPoint2f(blob->pts[i].x/640.0, blob->pts[i].y/480.0);            
                    }
                }           
            }  
            if(corner == 3){
                for(int i=0;i<blob->nPts;i++){
                    if(pGoal == ofxPoint2f() || (pGoal.x > blob->pts[i].x/640.0 && blob->pts[i].y > 240)){
                        pGoal = ofxPoint2f(blob->pts[i].x/640.0, blob->pts[i].y/480.0);            
                    }
                }           
            }   
        } else {
            if(corner == 1){
                for(int i=0;i<blob->nPts;i++){
                    if(pGoal == ofxPoint2f() || (pGoal.x > blob->pts[i].x/640.0 && blob->pts[i].y < 240 && blob->pts[i].x < 200)){
                        pGoal = ofxPoint2f(blob->pts[i].x/640.0, blob->pts[i].y/480.0);            
                    }
                }           
            }
            if(corner == 0){
                for(int i=0;i<blob->nPts;i++){
                    if(pGoal == ofxPoint2f() || (pGoal.x < blob->pts[i].x/640.0 && blob->pts[i].y < 240 && blob->pts[i].x > 400)){
                        pGoal = ofxPoint2f(blob->pts[i].x/640.0, blob->pts[i].y/480.0);            
                    }
                }           
            }
            if(corner == 2){
                for(int i=0;i<blob->nPts;i++){
                    if(pGoal == ofxPoint2f() || (pGoal.x < blob->pts[i].x/640.0)){
                        pGoal = ofxPoint2f(blob->pts[i].x/640.0, blob->pts[i].y/480.0);            
                    }
                }           
            }  
        }
        
        if(p != ofxPoint2f() && step == 1){
            p = p*0.95 + pGoal*0.05;
            if( p.distance(pGoal) > 0.01){
                pStable = NO;
                timer = 0;
            } else {
                timer ++;
                if(timer > 120){   
                    if(!depth){
                        int _c = corner;
                        if(corner == 2)
                            _c = 3;
                        if(corner == 3)
                            _c = 2;
                        [kinect setPoint2:_c coord:p];
                        [kinect calculateMatrix];
                        
                        NSBeep();
                        corner ++;
                        timer = 0;
                        
                        if((corner == 4 && !depth) || (corner == 3 && depth))
                            step = 2;
                    } else {
                        //Depth
                        XnPoint3D pIn;
                        pIn.X = p.x*640;
                        pIn.Y = p.y*480;
                        pIn.Z = depthBg[(int)pIn.X+(int)pIn.Y*640];
                        XnPoint3D pOut;
                        
                        if(pIn.Z != 0){
                            [kinect getDepthGenerator]->getXnDepthGenerator().ConvertProjectiveToRealWorld(1, &pIn, &pOut);
                            ofxPoint3f coord = ofxPoint3f(pOut.X, pOut.Y, pOut.Z);
                            [kinect setPoint3:corner coord:coord];
                            [kinect setPoint2:corner coord:p];
                        }
                        [kinect calculateMatrix];
                        NSBeep();
                        corner ++;
                        timer = 0;
                        
                        if((corner == 4 && !depth) || (corner == 3 && depth))
                            step = 2;
                    }
                }
                if(timer > 30){
                    pStable = YES;
                    
                } else {
                    pStable = NO;
                }
            }
        } else {
            p = pGoal;
        }
    } else {
        personFound = NO;
        p = ofxPoint2f();
        pStable = NO;
        timer = 0;
    }
    
    //  }
}

-(void)controlDraw:(NSDictionary *)drawingInformation{
    ofSetColor(255,255,255);
    diff->draw(0,0,ofGetWidth(),ofGetHeight());    
    tracker->draw(0, 0, ofGetWidth(),ofGetHeight());
    
    ofSetColor(0, 0, 255);
    ofNoFill();
    ofCircle(p.x * ofGetWidth(), p.y*ofGetHeight(),10);
    ofFill();
    
}
-(void)draw:(NSDictionary *)drawingInformation{
    ApplySurface(@"Screen");{
        ofSetColor(255,255,255);
        
        if(step < 2){
            glPushMatrix();
            if(depth){
                glTranslated(Aspect(@"Screen",0), 0, 0);
                glScaled(-1, 1, 1);
            }
            now->draw(0.1,0.1,1.7,0.8);
            if(step == 1)
                tracker->draw(0.1,0.1,1.7,0.8);
            
            if(personFound){
                ofSetColor(0,255,0,100);
            } else {
                ofSetColor(255,0,0,100);            
            }
            ofNoFill();
            ofRect(0.1,0.1,1.7,0.8);
            ofFill();
            
            if(step == 1){
                if(pStable){
                    ofSetColor(0, 255, 0);
                } else {
                    ofSetColor(0, 0, 255);
                    
                }
                ofNoFill();
                ofCircle(p.x*1.7 + 0.1, p.y*0.8 + 0.1,0.01);
                ofFill();
            }
            
            ofSetColor(255,255,0,255);
            glBegin(GL_LINE_STRIP);{
                for(int i=0;i<4;i++){
                    ofxPoint2f _p = [kinect surfaceCorner:i] * ofxPoint3f(1.0/640.0, 1.0/480.0,0);
                    glVertex2f(_p.x*1.7 + 0.1,_p.y*0.8 + 0.1);
                }
                ofxPoint2f _p = [kinect surfaceCorner:0] * ofxPoint3f(1.0/640.0, 1.0/480.0,0);;
                glVertex2f(_p.x*1.7 + 0.1,_p.y*0.8 + 0.1);           
            }glEnd();
            
            
            glPopMatrix();
            
            
            if(depth){
                ofSetColor(0, 255, 0);                      
                if(corner == 0 && step == 1){
                    ofCircle([kinect projPoint:0].x , [kinect projPoint:0].y, 0.005);
                }
                if(corner == 1 && step == 1){
                    ofCircle([kinect projPoint:1].x, [kinect projPoint:1].y, 0.005);
                }
                if(corner == 2 && step == 1){
                    ofCircle([kinect projPoint:2].x, [kinect projPoint:2].y, 0.005);
                }
            } else {
                ofSetColor(0, 255, 0);
                if(corner == 0 && step == 1){
                    ofCircle(0, 0, 0.005);
                }
                if(corner == 1 && step == 1){
                    ofCircle(Aspect(@"Screen",0), 0, 0.005);
                }
                if(corner == 2 && step == 1){
                    ofCircle(Aspect(@"Screen",0), 1, 0.005);
                }
                if(corner == 3 && step == 1){
                    ofCircle(0, 1, 0.005);
                }
            }
            
        } else {
            ofxPoint2f corners[4];
            for(int i=0;i<4;i++){
                corners[i] = [kinect surfaceCorner:i];
            }
            
            ofxPoint2f poly[4];
            
            poly[0] = ofxPoint2f(0.0,0.0);
            poly[1] = ofxPoint2f([kinect surfaceAspect],0.0);
            poly[2] = ofxPoint2f([kinect surfaceAspect],1.0);
            poly[3] = ofxPoint2f(0.0,1.0);
            
            
            TextureGrid texGrid;
            now->draw(0,0,0,0);
            texGrid.drawTextureGrid(&now->getTextureReference(),  poly, corners, 10);
            
        }
        
    }  PopSurface();
    
    
}

-(void) reset {
    step = 0;
    timer =0;
    corner = 0;
}
@end
