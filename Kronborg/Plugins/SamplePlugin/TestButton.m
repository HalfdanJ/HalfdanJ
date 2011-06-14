//
//  TestButton.m
//  kronborg
//
//  Created by Jonas Jongejan on 21/09/10.
//  Copyright 2010 HalfdanJ. All rights reserved.
//

#import "TestButton.h"


@implementation TestButton
-(void) performClick:(id)sender{
	NSLog(@"Click");
}

-(void) mouseDown:(NSEvent *)theEvent{
	[super mouseDown:theEvent];
	[self setState:1];
}


-(void) mouseUp:(NSEvent *)theEvent{
	NSLog(@"Up");
	//	[self setState:0];
	[super mouseUp:theEvent];
}
@end
