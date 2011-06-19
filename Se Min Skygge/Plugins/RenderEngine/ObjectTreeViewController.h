//
//  ObjectTreeViewController.h
//  SeMinSkygge
//
//  Created by Se Min Skygge on 19/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RenderEngine.h"

@interface ObjectTreeViewController : NSObject <NSOutlineViewDataSource> {
    RenderEngine * renderEngine;
    NSArray *draggedNodes;
    
    BOOL newObject;
}

-(id)initWithEngine:(RenderEngine*)engine 
;

@end
