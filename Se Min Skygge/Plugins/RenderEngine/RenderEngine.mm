#import "RenderEngine.h"
#import "Keystoner.h"

@implementation RenderEngine
@synthesize objectTreeController;
@synthesize objectsArray, assetDir;
@synthesize blurShader, ciContext;

-(void)initPlugin{
    objectsArray = [NSMutableArray array]; 
    assetDir = @"";
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:-1 maxValue:1] named:@"camPosX"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:-1 maxValue:1] named:@"camPosY"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:-1 maxValue:1] named:@"camPosZ"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:100] named:@"camDepthScale"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:100] named:@"depthBlur"];
    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"coreImageMode"];
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:5] named:@"assetTextureMode"];    
    [self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:0 minValue:0 maxValue:1] named:@"borderedRendering"];
    
}

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

-(void)willSave{
    [customProperties setObject:[self assetDir] forKey:@"assetDir"];
    [customProperties setObject:[self objectsArray] forKey:@"objects"];
}


-(void) placeCamera{
    glScaled(1,1,PropF(@"camDepthScale"));
    glTranslated(PropF(@"camPosX"),PropF(@"camPosY"),PropF(@"camPosZ"));
}

-(void)setup{
    CGLContextObj  contextGl = CGLContextObj([[[[[globalController viewManager] glViews] objectAtIndex:0] openGLContext] CGLContextObj]);		// the OpenGL context
	CGLPixelFormatObj pixelformatGl = CGLPixelFormatObj([[[[[globalController viewManager] glViews] objectAtIndex:0] pixelFormat] CGLPixelFormatObj]); // pixelformat object that specifies buffer types and other attributes of the context
	
    ciContext = [CIContext contextWithCGLContext:(CGLContextObj)contextGl pixelFormat:(CGLPixelFormatObj)pixelformatGl  colorSpace:CGColorSpaceCreateDeviceRGB() options:nil];
/*	ciContext = [[CIContext contextWithCGContext:(CGLContextObj)contextGl
                                     pixelFormat:(CGLPixelFormatObj)pixelformatGl 
                                      colorSpace:CGColorSpaceCreateDeviceRGB
										  options:[NSDictionary dictionaryWithObjectsAndKeys:
 nil]] retain];
*/
    
    
    NSLog(@"RenderEngine setup");
    fboFront = new ofxFBOTexture();
    fboBack = new ofxFBOTexture();
    fboFront->allocate(1024, 768, GL_RGBA);
    fboBack->allocate(1024, 768, GL_RGBA);
    
    fboFront->clear(0,0,0,0);
    fboBack->clear(0,0,0,0);   
    
    
    blurShader = new ofxShader();
    NSString *fragpath = [[NSBundle mainBundle] pathForResource:@"gaussianBlurShader" ofType:@"frag"];
    NSString *vertpath = [[NSBundle mainBundle] pathForResource:@"simpleBlurHorizontal" ofType:@"vert"];
	blurShader->loadShader([fragpath cStringUsingEncoding:NSUTF8StringEncoding],[vertpath cStringUsingEncoding:NSUTF8StringEncoding]);    
}

-(void) setupFboOpengl{
    int w = fboBack->texData.width;
    int h = fboBack->texData.height;	
    
    glViewport(0, 0, w, h);    
    float halfFov, theTan, screenFov, as;
    screenFov 		= 60;    
    float eyeX 		= (float)w / 2.0;
    float eyeY 		= (float)h / 2.0;
    halfFov 		= PI * screenFov / 360.0;
    theTan 			= tanf(halfFov);
    float dist 		= eyeY / theTan;
    float nearDist 	= dist / 10.0;	// near / far clip plane
    float farDist 	= dist * 10.0;
    as 			= (float)w/(float)h;    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(screenFov, as, nearDist, farDist);
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    gluLookAt(eyeX, eyeY, dist, eyeX, eyeY, 0.0, 0.0, 1.0, 0.0);
    
    glScalef(1, -1, 2);           // invert Y axis so increasing Y goes down.		    
    glTranslatef(0, -h, 0);       // shift origin up to upper-left corner.    
    glScaled(w,h,1);    
}

-(void) renderFbo{    
    NSArray * allObjects = [self allObjectsOrderedByDepth];   
    
    int time= ofGetElapsedTimeMillis();
    
    for(RenderObject * obj in allObjects){
        float dist = [obj posZ]+PropF(@"camPosZ");
        [obj setDepthBlurAmount:fabs(dist*PropF(@"depthBlur"))];

        [obj update];
    }
    
    if(ofGetElapsedTimeMillis()-time > 2){
        cout<<"Update time: "<<ofGetElapsedTimeMillis()-time<<endl;
    }
    time= ofGetElapsedTimeMillis();
    ofEnableAlphaBlending();
    fboBack->clear(0,0,0,255);
    fboBack->swapIn();{

        glPushMatrix();
        [self setupFboOpengl];
        [self placeCamera];
   //     glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        glBlendFuncSeparate(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA, GL_ONE,GL_ONE);

        for(RenderObject * obj in allObjects){
            if([obj backAlpha] > 0){
                [obj drawWithAlpha:[obj backAlpha]];
            } else if([obj maskBack]) {
                [obj drawMaskWithAlpha:1.0];
            }
        }
        glPopMatrix();
        
	}fboBack->swapOut();
    

    fboFront->clear();
    fboFront->swapIn();{
        glPushMatrix();
        
        [self setupFboOpengl];
        [self placeCamera];
   //     glBlendFunc(GL_ONE  , GL_ONE);


        for(RenderObject * obj in allObjects){
            if([obj frontAlpha] > 0){
                [obj drawWithAlpha:[obj frontAlpha]];
            }
        }
        glPopMatrix();
    }fboFront->swapOut();    
    ofEnableAlphaBlending();
    
    if(ofGetElapsedTimeMillis()-time > 2){
    cout<<"Render time: "<<ofGetElapsedTimeMillis()-time<<endl;
    }
    
        
    glViewport(0,0,ofGetWidth(),ofGetHeight());    
    ofSetupScreen();
    glScaled(ofGetWidth(), ofGetHeight(), 1);       
}

-(void)update:(NSDictionary *)drawingInformation{
    [Prop(@"camPosX") setFloatValue:sin(ofGetElapsedTimeMillis()/7000.0)];
    

}

-(void)controlDraw:(NSDictionary *)drawingInformation{
    ofEnableAlphaBlending();
    ofBackground(0,0,0);
    glScaled(ofGetWidth(), ofGetHeight(), 1);
    
    ofSetColor(255,255,255,255);
    
   // fboBack->draw(0,0,1,1);
   // fboFront->draw(0,0,1,1);
    glBlendFuncSeparate(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA, GL_ONE,GL_ONE);

    
    glPushMatrix();
    [self placeCamera];
//    glScaled(1,1,0.5);
    
    NSArray * allObjects = [self allObjectsOrderedByDepth];
    for(RenderObject * obj in allObjects){        
        if(obj == [self selectedObject]){
            [obj drawControlsWithColor:[NSColor greenColor]];
        } else {
            [obj drawControlsWithColor:[NSColor yellowColor]];
        }
    }
    
    glPopMatrix();
}

-(void)draw:(NSDictionary *)drawingInformation{
    [self renderFbo];

    
    ofBackground(0,0,0);
    glPushMatrix();
    ofDisableAlphaBlending();
    
    
    [GetPlugin(Keystoner)  applySurface:@"Screen" projectorNumber:0 viewNumber:ViewNumber];
    ofSetColor(255,255,255,255);
    fboFront->draw(0,0,1,1);
    [GetPlugin(Keystoner)  popSurface];
    
    [GetPlugin(Keystoner)  applySurface:@"Screen" projectorNumber:1 viewNumber:ViewNumber];
    ofSetColor(255,255,255,255);
    fboBack->draw(0,0,1,1);
    [GetPlugin(Keystoner)  popSurface];    
    glPopMatrix();   
    
    ofEnableAlphaBlending();

}

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

- (NSArray*) allObjectsOrderedByDepth{
    NSArray * allObjects = [self allObjects];
    NSSortDescriptor * descriptor =[[[NSSortDescriptor alloc] initWithKey:@"posZ" ascending:YES] autorelease];
    
    NSArray * descriptors = [NSArray arrayWithObjects:descriptor, nil];
    return [allObjects sortedArrayUsingDescriptors:descriptors];
}

- (RenderObject*) selectedObject{
    return [[objectTreeController selectedObjects] lastObject];
}

- (IBAction)addObject:(id)sender {
    NSLog(@"Add objects");
    RenderObject * newObject = [[RenderObject alloc] init];
    [newObject setEngine:self];
    [objectTreeController addObject:newObject];
}

- (IBAction)removeObject:(id)sender {
    [objectTreeController removeObject:[self selectedObject]];
}

- (IBAction)setAssset:(id)sender {
    if([[[objectTreeController selectedObjects] lastObject] assetString] != nil)
        [sender setStringValue:[[[objectTreeController selectedObjects] lastObject] assetString]];
}
@end
