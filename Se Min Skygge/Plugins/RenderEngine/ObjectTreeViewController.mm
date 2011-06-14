//
//  ObjectTreeViewController.m
//  SeMinSkygge
//
//  Created by Se Min Skygge on 19/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ObjectTreeViewController.h"
#import "RenderObject.h"

@implementation ObjectTreeViewController

- (id)initWithEngine:(RenderEngine *)engine
{
    self = [super init];
    if (self) {
        renderEngine = engine;
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}



-(BOOL) outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard{
    draggedNodes = items; // Don't retain since this is just holding temporaral drag information, and it is only used during a drag!  We could put this in the pboard actually.
    
    
    NSMutableArray * objectNames = [NSMutableArray array];
    for(id object in items){
        [objectNames addObject:[[object representedObject] name]];
    }
    
    [pasteboard declareTypes:[NSArray arrayWithObject:@"ObjectName"] owner:self];
    [pasteboard setData:[NSKeyedArchiver archivedDataWithRootObject:objectNames] forType:@"ObjectName"];
    
    return YES;
}

- (BOOL)treeNode:(NSTreeNode *)treeNode isDescendantOfNode:(NSTreeNode *)parentNode {
    while (treeNode != nil) {
        if (treeNode == parentNode) {
            return YES;
        }
        treeNode = [treeNode parentNode];
    }
    return NO;
}


-(NSDragOperation) outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index 
{
	// Check to see what we are proposed to be dropping on
	NSTreeNode *targetNode = item;
	// A target of "nil" means we are on the main root tree
    NSPasteboard *pboard = [info draggingPasteboard];

	
	if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"ObjectName"]] != nil) {
		for (NSTreeNode *draggedNode in draggedNodes) {
			if ([self treeNode:targetNode isDescendantOfNode:draggedNode]) {
				// Yup, it is, refuse it.
				return NSDragOperationNone;
			}
		}
	}
	
	if( [[info draggingSource] isKindOfClass:[outlineView class]]	){
		if([info draggingSource] == outlineView){
			return NSDragOperationMove;
		} else {
			return NSDragOperationCopy;			
		}
	} else if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        if(index ==  -1){
            NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
            int numberOfFiles = [files count];
            if(numberOfFiles > 1)
                return NSDragOperationNone;
            newObject = NO;  
            return NSDragOperationMove;
          
        } 
        newObject = YES;
        return NSDragOperationCopy;
    } else {
		return NSDragOperationNone;
	}
}




- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex {
    NSPasteboard *pboard = [info draggingPasteboard];

    NSTreeNode *targetNode = item;
	if(targetNode != nil){
		if (childIndex == NSOutlineViewDropOnItemIndex) {
			childIndex = 0;
		}
	}
    
    NSTreeController * treeController = [renderEngine objectTreeController];
    
    if([draggedNodes count] > 0){
        for(NSTreeNode * node in draggedNodes){
            NSLog(@"Drop %@ on %@",[node representedObject], [item representedObject]);
            RenderObject * obj = [node representedObject];
            RenderObject * target = [item representedObject];
            
            if([item representedObject] != nil){
                if(target != [obj parent]){
                    [target  addSubObject:obj];
                    
                    if([obj parent]){
                        [[obj parent] removeSubObject:obj];
                    } else {
                        [[renderEngine objectsArray] removeObject:obj];
                    }
                    [obj setParent:target];
                    [treeController rearrangeObjects];
                }
            } else if([obj parent]){
                [[renderEngine objectsArray] addObject:obj];
                
                if([obj parent]){
                    [[obj parent]  removeSubObject:obj];
                } 
                [obj setParent:nil];
                [treeController rearrangeObjects];
                
            }
            
        }
    } else if( [[pboard types] containsObject:NSFilenamesPboardType] ){
        RenderObject * target = [item representedObject];
        
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        int numberOfFiles = [files count];
        NSLog(@"%@ %i",files, numberOfFiles);
        
        if(newObject){
            for(int i=0;i<numberOfFiles;i++){
                RenderObject * newRenderObject = [[RenderObject alloc] init];
                [newRenderObject setEngine:renderEngine];
                [newRenderObject setAssetString:[files objectAtIndex:i]];
                [newRenderObject setAutoFill:YES]; 
                [newRenderObject setName:[[files objectAtIndex:i] lastPathComponent]];

                if(target != nil){
                    [target  addSubObject:newRenderObject];
                    [newRenderObject setParent:target];
                } else {
                    [renderEngine.objectTreeController addObject:newRenderObject];                    
                }
                [treeController rearrangeObjects];
            }
        } else {
            [target setAssetString:[files objectAtIndex:0]];
            if([[target name] isEqualToString:@""]){
                [target setName:[[files objectAtIndex:0] lastPathComponent]];
            }
        }
    }
	
    draggedNodes = nil;
	return YES;
    
    
}



@end
