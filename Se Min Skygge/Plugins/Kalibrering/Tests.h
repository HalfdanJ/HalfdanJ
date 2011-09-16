
#pragma once

#include "Plugin.h"

@interface Tests : NSObject{
    NSString * text;
    ofTrueTypeFont * font;    
}

@property (assign, readwrite) NSString * text;

-(void)draw:(NSDictionary *)drawingInformation;

@end
