#import "MyHTTPConnection.h"
#import "HTTPDynamicFileResponse.h"
//#import "HTTPResponseTest.h"
#import "HTTPLogging.h"

//#include "VideoPlayer.h"


// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;


@implementation MyHTTPConnection

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	// Use HTTPConnection's filePathForURI method.
	// This method takes the given path (which comes directly from the HTTP request),
	// and converts it to a full path by combining it with the configured document root.
	// 
	// It also does cool things for us like support for converting "/" to "/index.html",
	// and security restrictions (ensuring we don't serve documents outside configured document root folder).
	
	NSString *filePath = [self filePathForURI:path];
	
	// Convert to relative path
	
	NSString *documentRoot = [config documentRoot];
	
	if (![filePath hasPrefix:documentRoot])
	{
		// Uh oh.
		// HTTPConnection's filePathForURI was supposed to take care of this for us.
		return nil;
	}
	
	NSString *relativePath = [filePath substringFromIndex:[documentRoot length]];
	NSLog(@"%@  %@", relativePath, globalVideoPlayer);
	
	if ([relativePath length] > 1)
	{
		if([[relativePath substringToIndex:2] isEqualToString:@"/t"]){
			NSString * nsstr = [relativePath substringFromIndex:2];
			NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
			[f setNumberStyle:NSNumberFormatterDecimalStyle];
			long long val = [[f numberFromString:nsstr] longValue];
			
			[globalVideoPlayer setTimecode:val];							
		}
		if([[relativePath substringToIndex:2] isEqualToString:@"/v"]){
			NSString * nsstr = [relativePath substringFromIndex:2];
			NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
			[f setNumberStyle:NSNumberFormatterDecimalStyle];
			int val = [[f numberFromString:nsstr] intValue];
			
			[globalVideoPlayer setVideo:val];
		}
		
		if([[relativePath substringToIndex:2] isEqualToString:@"/r"]){
			NSString * nsstr = [relativePath substringFromIndex:2];
			NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
			[f setNumberStyle:NSNumberFormatterDecimalStyle];
			int val = [[f numberFromString:nsstr] intValue];
			NSLog(@"Set fade to %i",val);
			[globalVideoPlayer setVideoFade:val];
			

		}
		
		if([[relativePath substringToIndex:2] isEqualToString:@"/s"]){
			[globalVideoPlayer log:@"Was told to shut down now"];
			
			NSAppleEventDescriptor* returnDescriptor = NULL;
			NSDictionary* errorDict;
			
			NSAppleScript*  scriptObject= [[NSAppleScript alloc] initWithSource:
										   [NSString stringWithFormat:
											@"tell application \"Finder\" to shut down"] 
										   ];					
			returnDescriptor = [scriptObject executeAndReturnError: &errorDict];	
		}
		
	}
	return [super httpResponseForMethod:method URI:path];
}

@end
