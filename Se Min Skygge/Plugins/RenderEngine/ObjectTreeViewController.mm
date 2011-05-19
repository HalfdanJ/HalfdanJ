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
    
	
	if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"ObjectName"]] != nil) {
		for (NSTreeNode *draggedNode in draggedNodes) {
			if ([self treeNode:targetNode isDescendantOfNode:draggedNode]) {
				// Yup, it is, refuse it.
				return NSDragOperationNone;
			}
		}
	}
	
	
	if( [[info draggingSource] isKindOfClass:[outlineView class]]	)
	{
		if([info draggingSource] == outlineView){
			return NSDragOperationMove;
		} else {
			return NSDragOperationCopy;			
		}
	}
	else
	{
		return NSDragOperationNone;
	}
}




- (BOOL)outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)childIndex {
    NSTreeNode *targetNode = item;
    // A target of "nil" means we are on the main root tree
    //	NSMutableArray * childNodeArray;
	
	if(targetNode != nil){
        //	childNodeArray = [targetNode childNodes];
		
		if (childIndex == NSOutlineViewDropOnItemIndex) {
			// Insert it at the start, if we were dropping on it
			childIndex = 0;
		}
	} else {
        //	childNodeArray = [[cueTreeController arrangedObjects] childNodes];
	}
	
    NSTreeController * treeController = [renderEngine objectTreeController];
    
	//int i=0;
    //	NSTreeNode * lastNode = nil;
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
        
        /*
         NSTreeNode * previousNode = nil;
         
         if(lastNode == nil){
         if(childIndex > 0 || targetNode != nil){
         //Enten er det ikke den første node, eller det er en sub-node
         if(targetNode == nil){
         //Det er i roden
         previousNode = [[[treeController arrangedObjects] childNodes] objectAtIndex:childIndex-1];
         } else {
         if(childIndex == 0){
         //Øverst i en gruppe
         previousNode = targetNode;
         } else {
         //Midt i en gruppe
         previousNode = [[targetNode childNodes] objectAtIndex:childIndex-1];				
         }
         }
         }
         } else {
         previousNode = lastNode;
         }
         
         */
		//NSLog(@"Previous cue %i",[(NSNumber*)[[previousNode representedObject] lineNumber] intValue]);
		
		//	if(previousNode != nil){
		//		lineNumber = childIndex;	   
		//}
		
		
		/*if(([[node  representedObject] parent] == nil && targetNode == nil) || [[node  representedObject] parent] == [targetNode representedObject]){
         if([[(LQCueModel*)[node representedObject] lineNumber] intValue] < childIndex){
         childIndex --;
         }
         }
         
         if(previousNode != node){			
         //	[[node representedObject] setParent:[targetNode representedObject]];
         //	[self setLinenumber:lineNumber forCue:[node representedObject]];
         if(targetNode != nil){
         [[node representedObject] moveCueToGroup:[targetNode representedObject] atIndex:(int)childIndex];
         } else {
         [[node representedObject] moveCueToGroup:nil atIndex:(int)childIndex];				
         }
         }
         childIndex ++;
         
         lastNode = node;*/
	}
	
	//[[self cueTreeController] rearrangeObjects];
	
	//	[self setLinenumber:[(NSNumber*)[[previousNode representedObject] lineNumber] intValue]+1 forCue:<#(CueModel *)cue#>
	
	return YES;
    
    
}



@end
