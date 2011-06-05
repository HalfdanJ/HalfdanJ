#pragma once

#include "Plugin.h"
#import <netinet/in.h>
#import <sys/socket.h>
#import <SystemConfiguration/SystemConfiguration.h>

//#import "BSender.h"
//#import "BReceiver.h"
#import <QTKit/QTKit.h>

//#import "ArduinoController.h"

@class QTMovie;
#define NUMVIDEOS 20

@interface VideoPlayer : ofPlugin {
	QTMovie     		*movie[NUMVIDEOS];
	QTVisualContextRef	textureContext[NUMVIDEOS];
	CVOpenGLTextureRef  currentFrame[NUMVIDEOS];
	NSSize sizes[NUMVIDEOS];
	
	int lastFramesVideo;
	BOOL forceDrawNextFrame;
//	ArduinoController * arduino;
	NSMutableArray * loadedFiles;
	IBOutlet NSArrayController * loadedFilesController;
	BOOL cancelReboot;
	
	IBOutlet NSPopUpButton * videoSelector;
	IBOutlet NSPopUpButton * chapterSelector;

    NSString * basePath;
    NSString * fileName;
    int numberVideos;

}
@property (readwrite) NSString * basePath;
@property (readwrite) NSString * fileName;
@property (readwrite) int numberVideos;
@property (readwrite, retain) NSMutableArray * loadedFiles;

-(IBAction) restart:(id)sender;

-(QTMovie*) getMovie:(int)movie;
-(QTMovie*) getCurrentMovie;
-(void) setCurrentMovie:(int)movie;
-(int) getCurrentMovieIndex;

@end
