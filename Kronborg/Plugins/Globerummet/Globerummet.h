#pragma once

#include "Plugin.h"

#include "VideoPlayer.h"

//#import "ofxOsc.h"
#import <netinet/in.h>
#import <sys/socket.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import <QTKit/QTKit.h>

#import "ArduinoController.h"
#include "ofxOsc.h"

//#define USE_QTKIT 
@class QTMovie;
#define NUMVIDEOS 13
#define NUMDMX 2


@interface Globerummet : ofPlugin {
	int lastFramesVideo;
	
	NSString * keys[NUMVIDEOS][2];
	
	float whiteFlash;

	ArduinoController * arduino;

	NSDate * timecodeSetterTimer;
	
	IBOutlet NSBox * styringbox;
	IBOutlet NSBox * kalibbox;
	IBOutlet NSTextField * arduinoConnectionText;
	IBOutlet NSImageView * arduinoConnectionImage;
	
	IBOutlet NSTextField * globusButtonText;
	
	IBOutlet NSTextField * lightText;

	
	IBOutlet NSTextField * networkConnectionText1;
	IBOutlet NSImageView * networkConnectionImage1;
	IBOutlet NSTextField * networkConnectionText2;
	IBOutlet NSImageView * networkConnectionImage2;
	
	IBOutlet NSTextField * bigLabel;

	IBOutlet NSButton * testButton;
	int testCounter;

	
	long long timecodeDifference;
	BOOL forceDrawNextFrame;
	
/*	SCNetworkConnectionFlags globus2flags;
	SCNetworkConnectionFlags globus3flags;
	
	ofxOscSender * osender[4];
	ofxOscReceiver * oreceiver;
*/	
	NSString * postTimeBuffer;
	
	NSMutableArray * loadedFiles;
	IBOutlet NSArrayController * loadedFilesController;
	
	ofImage * maske;
	ofImage * flashImage;
	
	
	vector<int> framerateAvg;
	int lowFramerateCounter;
	NSDate * lastMsgDate;
    
    VideoPlayer * videoPlayer;
}

@property (readwrite, retain) NSMutableArray * loadedFiles;
/*
@property (readwrite, retain) NSNetServiceBrowser *browser;
@property (readwrite, retain) NSMutableArray *services;
//@property (readwrite, assign) BOOL isConnected;
@property (readwrite, retain) NSNetService *connectedService;

 
-(IBAction) load:(id)sender;
*/

-(IBAction) restart:(id)sender;
-(IBAction) testButton:(id)sender;

-(void) sleepComputer;
-(void) restartApplication;
@end
