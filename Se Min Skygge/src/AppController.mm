//
//  AppController.m
//
//  Created by Jonas Jongejan on 03/11/09.
//

#import "AppController.h"
#include "PluginIncludes.h"
#include "testApp.h"
#include "ofAppCocoaWindow.h"

extern testApp * OFSAptr;
extern ofAppBaseWindow * window;

@implementation AppController

-(void) setupApp{
	[pluginManagerController setNumberOutputViews:1];	
}


-(void) awakeFromNib {
	baseApp = OFSAptr;
	cocoaWindow = window;	
	((ofAppCocoaWindow*)cocoaWindow)->windowController = self;
	
	ofSetBackgroundAuto(false);
	
}

-(void) setupPlugins{
	[pluginManagerController addHeader:@"Core Plugin"];

    [pluginManagerController addPlugin:[[Keystoner alloc] initWithSurfaces:[NSArray arrayWithObjects:@"Screen", nil]]];
    [pluginManagerController addPlugin:[[Kinect alloc] initWithNumberKinects:2]];
    [pluginManagerController addPlugin:[[BlobTracker2d alloc] init]];
    [pluginManagerController addPlugin:[[Midi  alloc] init]];    
    
    [pluginManagerController addHeader:@"Plugins"];

 //   [pluginManagerController addPlugin:[[VideoPlayer alloc] init]];	
   /* [pluginManagerController addPlugin:[[RenderEngine alloc] init]];
  */  [pluginManagerController addPlugin:[[Shadows alloc] init]];
   /* [pluginManagerController addPlugin:[[InteractiveWall alloc] init]];
    [pluginManagerController addPlugin:[[ShadowFog alloc] init]];
    [pluginManagerController addPlugin:[[Fireflies alloc] init]];
    [pluginManagerController addPlugin:[[Handshadows alloc] init]];

*/

}

@end
