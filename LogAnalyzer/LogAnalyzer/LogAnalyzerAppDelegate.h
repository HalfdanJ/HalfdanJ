//
//  LogAnalyzerAppDelegate.h
//  LogAnalyzer
//
//  Created by Jonas Jongejan on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LogAnalyzerAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *_window;
    
    NSMutableArray * array;
}

@property (strong) IBOutlet NSWindow *window;

@end
