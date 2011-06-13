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
	[pluginManagerController addHeader:@"Plugins"];
    
	[pluginManagerController addPlugin:[[VideoPlayer alloc] init]];
    
	[pluginManagerController addPlugin:[[Keystoner alloc] initWithSurfaces:[NSArray arrayWithObjects:@"", nil]]];


}

@end
