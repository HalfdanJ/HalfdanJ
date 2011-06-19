#pragma once

#include "Plugin.h"
//#import "ofxOsc.h"
#import <netinet/in.h>
#import <sys/socket.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "BSender.h"
#import "BReceiver.h"
#import <QTKit/QTKit.h>

#import "ArduinoController.h"
#include "ofxNetwork.h"

@class HTTPServer;

//#define USE_QTKIT 
@class QTMovie;
#define NUMVIDEOS 13
#define NUMDMX 2


@interface VideoPlayer : ofPlugin{
	QTMovie     		*movie[NUMVIDEOS];
	QTMovie				*activateSound[NUMVIDEOS];
	QTVisualContextRef	textureContext[NUMVIDEOS];
	CVOpenGLTextureRef  currentFrame[NUMVIDEOS];
	
	int lastFramesVideo;
	
	NSString * keys[NUMVIDEOS][2];
	
	float whiteFlash;
/*	float fadeDown;
	int fadeDirection;
*/	
	NSMutableArray * lightCues;
	QTTime lastLightTime;
	
	ArduinoController * arduino;

	/*ofxOscSender * oscSender[4];
	ofxOscSender * oscDirectSender[4];
	ofxOscReceiver * oscReceiver;
	*/
	NSDate * latencyTimer;
	NSDate * timecodeSetterTimer;
	
	IBOutlet NSBox * styringbox;
	IBOutlet NSBox * kalibbox;
	IBOutlet NSTextField * arduinoConnectionText;
	IBOutlet NSImageView * arduinoConnectionImage;
	
	IBOutlet NSTextField * globusButtonText;
	
	IBOutlet NSTextField * lightText;

	IBOutlet NSTextField * versionText;
	IBOutlet NSTextField * videoText;
	
	IBOutlet NSTextField * networkConnectionText1;
	IBOutlet NSImageView * networkConnectionImage1;
	IBOutlet NSTextField * networkConnectionText2;
	IBOutlet NSImageView * networkConnectionImage2;
	
	IBOutlet NSTextField * bigLabel;

	IBOutlet NSButton * testButton;
	int testCounter;

	
	long long timecodeDifference;
	BOOL forceDrawNextFrame;
	
	SCNetworkConnectionFlags globus2flags;
	SCNetworkConnectionFlags globus3flags;
/*	
	BReceiver * breceiver;
	BSender * bsender[4];
	ofxOscSender * osender[4];
	ofxOscReceiver * oreceiver;
*/	
	/*ofxTCPClient * tcpClient;
	ofxTCPServer * tcpServer;
	bool weConnected;
	int connectTime;
	int deltaTime;
	int msgTime;
*/
	HTTPServer *httpServer;

	
	float dmxValue[NUMDMX];
	
	NSString * postTimeBuffer;
	
	NSMutableArray * loadedFiles;
	IBOutlet NSArrayController * loadedFilesController;
	
	ofImage * maske;
	ofImage * flashImage;
    
    BOOL alreadyShutdown;
	
	
	vector<int> framerateAvg;
	int lowFramerateCounter;
	NSDate * lastMsgDate;
	
	BOOL restarting;
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
