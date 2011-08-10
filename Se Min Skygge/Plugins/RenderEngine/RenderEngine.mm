#import "RenderEngine.h"
#import "Keystoner.h"
#import "ObjectTreeViewController.h"

@implementation RenderEngine
@synthesize objectTreeController;
@synthesize objectsArray, assetDir, aspect;
@synthesize blurShader, ciContext, treeController, midi;

//------------------------------------------------------------------------------------------------------------------------

-(void)initPlugin{
    objectsArray = [NSMutableArray array]; 
    assetDir = @"";
    
    treeController = [[ObjectTreeViewController alloc] initWithEngine:self];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:3] named:@"camPosX"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:-1 maxValue:1] named:@"camPosY"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:-1 maxValue:1] named:@"camPosZ"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:100] named:@"camDepthScale"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:100] named:@"depthBlur"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"coreImageMode"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:5] named:@"assetTextureMode"];    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"borderedRendering"];    
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"levelsMin"];    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1 minValue:0 maxValue:1] named:@"levelsMax"];    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0.5 minValue:0 maxValue:1] named:@"levelsMiddle"];
    
    float p = 10.0;
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:127] named:@"objSelection"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:-63/p maxValue:64/p] named:@"objX"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:-63/64.0 maxValue:64/64.0] named:@"objY"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:-63/6.0 maxValue:64/6.0] named:@"objZ"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"objPlay"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"objLoop"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:127] named:@"objChapterStart"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:127] named:@"objChapterStop"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"objOpacity"];
    [self addProperty:[BoolProperty boolPropertyWithDefaultvalue:NO] named:@"resetAll"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"switchProjector"];

    
    [Prop(@"objX") setMidiSmoothing:0.90];
    [Prop(@"objY") setMidiSmoothing:0.9];
    [Prop(@"objZ") setMidiSmoothing:0.95];
    [Prop(@"objOpacity") setMidiSmoothing:0.9];
    
    [self assignMidiChannel:10];
}

//------------------------------------------------------------------------------------------------------------------------

-(void)awakeFromNib{
    [super awakeFromNib];
    [objectOutlineView setDataSource:treeController];
    [objectOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:@"ObjectName",NSURLPboardType, nil]];
}

//------------------------------------------------------------------------------------------------------------------------


-(void)customPropertiesLoaded{
    if([customProperties objectForKey:@"assetDir"] != nil)
        [self setAssetDir:[customProperties objectForKey:@"assetDir"]];
    
    if([customProperties objectForKey:@"objects"] != nil)
        [self setObjectsArray:[customProperties objectForKey:@"objects"]];
    
    NSArray * allObjects = [self allObjects];
    for(RenderObject * obj in allObjects){
        [obj setEngine:self];
    }
}

//------------------------------------------------------------------------------------------------------------------------

-(void)willSave{
    [customProperties setObject:[self assetDir] forKey:@"assetDir"];
    [customProperties setObject:[self objectsArray] forKey:@"objects"];
}

//------------------------------------------------------------------------------------------------------------------------

-(void)setup{
    midi = GetPlugin(Midi);
    aspect = [[[GetPlugin(Keystoner) getSurface:@"Screen" viewNumber:0 projectorNumber:0] aspect] floatValue];
    
    
    CGLContextObj  contextGl = CGLContextObj([[[[[globalController viewManager] glViews] objectAtIndex:0] openGLContext] CGLContextObj]);
	CGLPixelFormatObj pixelformatGl = CGLPixelFormatObj([[[[[globalController viewManager] glViews] objectAtIndex:0] pixelFormat] CGLPixelFormatObj]);	
    ciContext = [CIContext contextWithCGLContext:contextGl pixelFormat:pixelformatGl  colorSpace:CGColorSpaceCreateDeviceRGB() options:nil];
    
    
    for(int i=0;i<2;i++){
        fboFront[i] = new ofxFBOTexture();
        fboBack[i] = new ofxFBOTexture();
        fboFront[i]->allocate(1024, 1024*1.0/aspect, GL_RGBA);
        fboBack[i]->allocate(1024, 1024*1.0/aspect, GL_RGBA);
        
        fboFront[i]->clear(0,0,0,0);
        fboBack[i]->clear(0,0,0,0);  
    }
    
    colorCorrectShader = new ofxShader();
    NSString *fragpath = [[NSBundle mainBundle] pathForResource:@"colorCorrectShader" ofType:@"frag"];
    NSString *vertpath = [[NSBundle mainBundle] pathForResource:@"colorCorrectShader" ofType:@"vert"];
    colorCorrectShader->loadShader([fragpath cStringUsingEncoding:NSUTF8StringEncoding],[vertpath cStringUsingEncoding:NSUTF8StringEncoding]); 
    
    
    camCoord = ofxVec3f(0,0,-5);
    eyeCoord = ofxVec3f(0,0,1);
    
    //   glEnable(GL_DEPTH_TEST);
    
    dispatch_async(dispatch_get_main_queue(), ^{		
        NSArray * allObjects = [self allObjects];       
        for(RenderObject * obj in allObjects){
            [obj loadAsset];
        }
    });
    
    //Midi bindings
    //[[[GetPlugin(Midi) midiData] objectAtIndex:[[self midiChannel] intValue]] addObserver:self forKeyPath:@"0" options:0 context:nil];
    
    
}

//------------------------------------------------------------------------------------------------------------------------

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if(object == Prop(@"objSelection")){
        NSArray * allObjects = [self allObjectsOrderedByDepth];       
        for(RenderObject * obj in allObjects){
            if([obj objId] == [object intValue]){
                selectedObject = obj;
                break;
            }
        }
        
        [Prop(@"objX") clearSmoothing];
        [Prop(@"objY") clearSmoothing];
        [Prop(@"objZ") clearSmoothing];
        [Prop(@"objOpacity") clearSmoothing];
        
    }
    if(object == Prop(@"resetAll") && [object boolValue]){   
        [object setBoolValue:NO];
        NSArray * a = [self allObjects];
        for(RenderObject * obj in a){
            if([obj objId] != 0){
                [obj setVisible:NO];
                [obj setPlay:NO];
                [obj setChapterFrom:0];
                [obj setChapterTo:127];
            }
        }
    }
    
    if(selectedObject != nil){
        if(object == Prop(@"objX")){            
            [selectedObject setPosX:[object floatValue]];
        }
        if(object == Prop(@"objY")){            
            [selectedObject setPosY:[object floatValue]];
        }
        if(object == Prop(@"objZ")){            
            [selectedObject setPosZ:[object floatValue]];
        }
        if(object == Prop(@"objPlay")){            
            [selectedObject setPlay:[object boolValue]];
        }
        if(object == Prop(@"objLoop")){            
            [selectedObject setLoop:[object boolValue]];
        }
        if(object == Prop(@"objChapterStart")){            
            [selectedObject setChapterFrom:[object intValue]];
        }
        if(object == Prop(@"objChapterStop")){            
            [selectedObject setChapterTo:[object intValue]];
        }
        if(object == Prop(@"objOpacity")){            
            float op = [object floatValue];
            if(op == 0){
                [selectedObject setVisible:NO];
            } else {
                [selectedObject setVisible:YES];
                [selectedObject setOpacity:op];
            }
        }
    }
    
}

//------------------------------------------------------------------------------------------------------------------------

-(void)update:(NSDictionary *)drawingInformation{
    if([autoPanCheckbox state]){
        [Prop(@"camPosX") setFloatValue:sin(CFAbsoluteTimeGetCurrent()/7.0*[autoPanSpeed floatValue])*0.5+0.5];
    }    
    
    NSArray * allObjects = [self allObjectsOrderedByDepth];       
    //NSArray * rootsObjects = [self rootObjectsOrdredByDepth];       
    
    int timer = ofGetElapsedTimeMillis();    
    
    for(RenderObject * obj in allObjects){
        if([obj absoluteVisible]){
            float dist = [obj absolutePosZ]+PropF(@"camPosZ");
            [obj setDepthBlurAmount:fabs(dist*PropF(@"depthBlur"))];        
            [obj update:drawingInformation];
        }
    }
    
    
    if(ofGetElapsedTimeMillis()-timer > 2){
        cout<<"Update time: "<<ofGetElapsedTimeMillis()-timer<<endl;
    }
    timer= ofGetElapsedTimeMillis();
}

//------------------------------------------------------------------------------------------------------------------------


-(void)controlDraw:(NSDictionary *)drawingInformation{
    ofEnableAlphaBlending();
    ofBackground(0,0,0);
    glScaled(ofGetWidth(), ofGetHeight(), 1);
    ofSetColor(255,255,255,255);
    glBlendFuncSeparate(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA, GL_ONE,GL_ONE);
    
    glPushMatrix();{
        glScaled(1.0/aspect,1,100);        
        ofxVec3f v = eyeCoord-camCoord;
        float a1 = ofxVec2f(0, 1).angle(ofxVec2f(eyeCoord.x, eyeCoord.z)-ofxVec2f(camCoord.x, camCoord.z));    
        v.rotate(a1, ofxVec3f(0,1,0));    
        float a2 = ofxVec2f(1, 0).angle(ofxVec2f(v.z,v.y));
        glRotated(a2, 1, 0, 0);
        glRotated(a1, 0, 1, 0);
        glTranslated(camCoord.x, camCoord.y,camCoord.z);
        
        NSArray * allObjects = [self allObjectsOrderedByDepth];
        for(RenderObject * obj in allObjects){      
            if([obj absoluteVisible]){
                if(obj == [self selectedObject]){
                    [obj drawControlsWithColor:[NSColor greenColor]];
                } else {
                    [obj drawControlsWithColor:[NSColor yellowColor]];
                }
            }
        }
        
        //Cam:
        glPushMatrix();{
            glTranslated(1, 0.5, 10.0/3.0);
            glTranslated(PropF(@"camPosX"),-PropF(@"camPosY"),-PropF(@"camPosZ"));
            glScaled(aspect,1,1);
            
            glColor4f(1.0f,0.4f,0.3f,0.7f);
            glBegin(GL_LINES);
            glVertex3d(0, 0, 0);
            glVertex3d(-1.6/2.0, 1.6/2.0, -10.0/3.0-2);
            
            glVertex3d(0, 0, 0);
            glVertex3d(1.6/2.0, 1.6/2.0, -10.0/3.0-2);
            
            glVertex3d(0, 0, 0);
            glVertex3d(-1.6/2.0, -1.6/2.0, -10.0/3.0-2);
            
            glVertex3d(0, 0, 0);
            glVertex3d(1.6/2.0, -1.6/2.0, -10.0/3.0-2);
            
            
            glVertex3d(1.0/2.0, 1.0/2.0, -10.0/3.0);
            glVertex3d(1.0/2.0, -1.0/2.0, -10.0/3.0);
            
            glVertex3d(-1.0/2.0, 1.0/2.0, -10.0/3.0);
            glVertex3d(-1.0/2.0, -1.0/2.0, -10.0/3.0);
            
            glVertex3d(1.0/2.0, -1.0/2.0, -10.0/3.0);
            glVertex3d(-1.0/2.0, -1.0/2.0, -10.0/3.0);
            
            glVertex3d(1.0/2.0, 1.0/2.0, -10.0/3.0);
            glVertex3d(-1.0/2.0, 1.0/2.0, -10.0/3.0);
            
            glEnd();          
            
            glColor4f(1.0f,0.4f,0.3f,0.2f);
            
            glBegin(GL_TRIANGLE_FAN);
            glVertex3d(0, 0, 0);
            glVertex3d(-1.6/2.0, 1.6/2.0, -10.0/3.0-2);
            glVertex3d(1.6/2.0, 1.6/2.0, -10.0/3.0-2);
            glVertex3d(1.6/2.0, -1.6/2.0, -10.0/3.0-2);
            glVertex3d(-1.6/2.0, -1.6/2.0, -10.0/3.0-2);
            glVertex3d(-1.6/2.0, 1.6/2.0, -10.0/3.0-2);
            glEnd();     
            
        }glPopMatrix();
        
    }glPopMatrix();
    
    
}

//------------------------------------------------------------------------------------------------------------------------

-(void) placeCamera{
    /* glScaled(1.0/aspect,1,PropF(@"camDepthScale"));        
     
     
     glScaled(1.0/aspect,1,PropF(@"camDepthScale"));
     glTranslated(-PropF(@"camPosX")+0.5,PropF(@"camPosY"),PropF(@"camPosZ"));
     */
    
    float scale = PropF(@"camDepthScale")/100.0;
    scale = 1.0/(1+PropF(@"camPosZ") * -0.3*scale);
    
    glTranslated(0.5*aspect,0.5,0);
    glScaled(scale,scale,0);
    glTranslated(-0.5*aspect,-0.5,0);
    
    glTranslated(-PropF(@"camPosX"),PropF(@"camPosY"),0);
    
    
    
    
    
}


//------------------------------------------------------------------------------------------------------------------------


-(void)draw:(NSDictionary *)drawingInformation{
    /*  [self renderFbo];
     
     
     ofBackground(0,0,0);
     glPushMatrix();
     ofDisableAlphaBlending();
     
     colorCorrectShader->setShaderActive(YES);
     colorCorrectShader->setUniformVariable1f((char*)"min", PropF(@"levelsMin") );
     colorCorrectShader->setUniformVariable1f((char*)"max", PropF(@"levelsMax"));
     
     colorCorrectShader->setUniformVariable2f((char*)"start", 0.0, 0.0);
     colorCorrectShader->setUniformVariable2f((char*)"middle",0.5, PropF(@"levelsMiddle"));    
     colorCorrectShader->setUniformVariable2f((char*)"end", 1.0, 1.0);    
     
     [GetPlugin(Keystoner)  applySurface:@"Screen" projectorNumber:0 viewNumber:ViewNumber];
     ofSetColor(255,255,255,255);
     fboFront[pingpong]->draw(0,0,Aspect(@"Screen",0),1);
     [GetPlugin(Keystoner)  popSurface];
     
     [GetPlugin(Keystoner)  applySurface:@"Screen" projectorNumber:1 viewNumber:ViewNumber];
     ofSetColor(255,255,255,255);
     fboBack[pingpong]->draw(0,0,Aspect(@"Screen",0),1);
     [GetPlugin(Keystoner)  popSurface];    
     glPopMatrix();   
     colorCorrectShader->setShaderActive(NO);
     
     ofEnableAlphaBlending();
     
     */
    
    glPushMatrix();
    
    //Back
    NSArray * allObjectsBack = [self allObjectsOrderedByDepthBack];       
    NSArray * allObjects = [self allObjectsOrderedByDepth];       
    
    [GetPlugin(Keystoner)  applySurface:@"Screen" projectorNumber:1 viewNumber:ViewNumber];
    glPushMatrix();
    [self placeCamera];
    
    for(RenderObject * obj in allObjectsBack){
        glPushMatrix();
        if([obj absoluteVisible]){
            if([obj blendmodeAdd]){
                glBlendFunc(GL_SRC_ALPHA, GL_ONE);
            } else {
                glBlendFuncSeparate(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA, GL_ONE,GL_ONE);        
            }
            
            if([obj backAlpha]*(PropF(@"switchProjector")) > 0){
                [obj drawWithAlpha:[obj backAlpha]*(PropF(@"switchProjector")) front:NO];
            } else if([obj maskBack]) {
                [obj drawMaskWithAlpha:1.0];
            }
            
            
            glPushMatrix();
            
            if([obj absoluteVisible]){
                if([obj frontAlpha]*(1-PropF(@"switchProjector")) > 0){
                    [obj drawWithAlpha:[obj frontAlpha]*(1-PropF(@"switchProjector")) front:YES];
                }
            }
            glPopMatrix();
        }
        glPopMatrix();
        
        //Draw any front mask now
        for(RenderObject * frontObj in allObjects){
            //All the objects closer the obj
            if(frontObj != obj && [frontObj stackMode] == 3 && [frontObj absolutePosZ] > [obj absolutePosZBack]){
                glPushMatrix();
                if([frontObj absoluteVisible]){
                    if([frontObj frontAlpha] > 0){
                        [frontObj drawMaskWithAlpha:[frontObj frontAlpha]];
                    }

                }
                glPopMatrix();
                
            }
            
            
        }
        
    }
    glPopMatrix();
    ofDisableAlphaBlending();
    ofFill();
    ofSetColor(0, 0, 0);
    ofRect(-10, 0, 20, -10);
    ofRect(-10, 1, 20, 10);
    ofRect(0, -10, -10, 20);
    ofRect(aspect, -10, 10, 20);
    
    [GetPlugin(Keystoner)  popSurface];    
    
    glPopMatrix();     
    
    
    //Front
    //    glPushMatrix();
    
    //    [self setupFboOpengl];
    glPushMatrix();
    
    [GetPlugin(Keystoner)  applySurface:@"Screen" projectorNumber:0 viewNumber:ViewNumber];
    glPushMatrix();
    
    [self placeCamera];
    
    for(RenderObject * obj in allObjects){
        glPushMatrix();
        
        if([obj absoluteVisible]){
            if([obj frontAlpha]*PropF(@"switchProjector") > 0){
                [obj drawWithAlpha:[obj frontAlpha]*PropF(@"switchProjector") front:YES];
            }
        }
        glPopMatrix();
        
        glPushMatrix();
        if([obj absoluteVisible]){
            if([obj blendmodeAdd]){
                glBlendFunc(GL_SRC_ALPHA, GL_ONE);
            } else {
                glBlendFuncSeparate(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA, GL_ONE,GL_ONE);        
            }
            
            if([obj backAlpha] * (1-PropF(@"switchProjector")) > 0){
                [obj drawWithAlpha:[obj backAlpha]* (1-PropF(@"switchProjector")) front:NO];
            } else if([obj maskBack]) {
                [obj drawMaskWithAlpha:1.0];
            }
        }
        glPopMatrix();
        
        
    }
    
    glPopMatrix();
    ofDisableAlphaBlending();
    ofFill();
    ofSetColor(0, 0, 0);
    ofRect(-10, 0, 20, -10);
    ofRect(-10, 1, 20, 10);
    ofRect(0, -10, -10, 20);
    ofRect(aspect, -10, 10, 20);
    [GetPlugin(Keystoner)  popSurface];    
    
    glPopMatrix();
    
    
    
}

//------------------------------------------------------------------------------------------------------------------------


-(void) setupFboOpengl{
    
}


//------------------------------------------------------------------------------------------------------------------------


-(void) renderFbo{        
}

//------------------------------------------------------------------------------------------------------------------------


- (int) updateFlags{
    int ret = 0;
    if(PropI(@"assetTextureMode") > 0)
        ret |= USE_ASSET_TEXTURE;
    
    if(PropI(@"assetTextureMode") > 1)
        ret |= USE_CIIMAGE;
    
    if(PropI(@"assetTextureMode") > 2)
        ret |= USE_CI_FBO;
    
    if(PropB(@"borderedRendering") == 1)
        ret |= USE_BORDERED_FBO;
    
    if(PropB(@"coreImageMode") == 1)
        ret |= FILTER_CIIMAGE;    
    
    return ret;
}

//------------------------------------------------------------------------------------------------------------------------

- (NSArray*) allObjects{
    NSMutableArray * arr = [NSMutableArray arrayWithArray:objectsArray];
    
    for(int i=0;i<[arr count];i++){
        if([[[arr objectAtIndex:i] subObjects] count] > 0){
            NSMutableIndexSet * indexset = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(i+1, [[[arr objectAtIndex:i] subObjects] count])];
            [arr insertObjects:[[arr objectAtIndex:i] subObjects] atIndexes:indexset];
        }
    }
    
    return arr;
}

//------------------------------------------------------------------------------------------------------------------------


- (NSArray*) allObjectsOrderedByDepth{
    NSArray * allObjects = [self allObjects];
    NSSortDescriptor * descriptor =[[[NSSortDescriptor alloc] initWithKey:@"absolutePosZ" ascending:YES] autorelease];
    
    NSArray * descriptors = [NSArray arrayWithObjects:descriptor, nil];
    return [allObjects sortedArrayUsingDescriptors:descriptors];
}

- (NSArray*) allObjectsOrderedByDepthBack{
    NSArray * allObjects = [self allObjects];
    NSSortDescriptor * descriptor =[[[NSSortDescriptor alloc] initWithKey:@"absolutePosZBack" ascending:YES] autorelease];
    
    NSArray * descriptors = [NSArray arrayWithObjects:descriptor, nil];
    return [allObjects sortedArrayUsingDescriptors:descriptors];
}

//------------------------------------------------------------------------------------------------------------------------


-(NSArray*) rootObjectsOrdredByDepth{
    NSSortDescriptor * descriptor =[[[NSSortDescriptor alloc] initWithKey:@"absolutePosZ" ascending:YES] autorelease];
    
    NSArray * descriptors = [NSArray arrayWithObjects:descriptor, nil];
    return [objectsArray sortedArrayUsingDescriptors:descriptors];
    
}

//------------------------------------------------------------------------------------------------------------------------

- (RenderObject*) selectedObject{
    return [[objectTreeController selectedObjects] lastObject];
}

//------------------------------------------------------------------------------------------------------------------------


- (IBAction)addObject:(id)sender {
    RenderObject * newObject = [[RenderObject alloc] init];
    [newObject setEngine:self];
    [objectTreeController addObject:newObject];
}

//------------------------------------------------------------------------------------------------------------------------

- (IBAction)removeObject:(id)sender {
    [objectTreeController remove:[self selectedObject]];
}

//------------------------------------------------------------------------------------------------------------------------


- (IBAction)setAssset:(id)sender {
    if([[[objectTreeController selectedObjects] lastObject] assetString] != nil)
        [sender setStringValue:[[[objectTreeController selectedObjects] lastObject] assetString]];
}

//------------------------------------------------------------------------------------------------------------------------


- (IBAction)resetCam:(id)sender {
    [Prop(@"camPosX") setFloatValue:0.0];
    [Prop(@"camPosY") setFloatValue:0.0];
    [Prop(@"camPosZ") setFloatValue:0.0];
}

//------------------------------------------------------------------------------------------------------------------------

-(void)controlMouseScrolled:(NSEvent *)theEvent{
    float deltaY = -[theEvent deltaY]*0.02;
    ofxVec3f v = camCoord - eyeCoord;
    camCoord = eyeCoord + v + v.normalized()*deltaY;
}

//------------------------------------------------------------------------------------------------------------------------

-(void)controlMousePressed:(float)x y:(float)y button:(int)button{
    mouseLastX = x; mouseLastY = y;
}

//------------------------------------------------------------------------------------------------------------------------

-(void)controlMouseDragged:(float)x y:(float)y button:(int)button{
    ofxVec3f v = camCoord - eyeCoord;
    v.rotate(-(x - mouseLastX)*0.2, ofxVec3f(0,1,0));
    v.rotate((y - mouseLastY)*0.2, ofxVec3f(-v.z,0,v.x));
    
    camCoord = eyeCoord + v;
    mouseLastX = x; mouseLastY = y;
}

@end
