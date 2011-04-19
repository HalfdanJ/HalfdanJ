#include "Plugin.h"

@interface Parsifal : ofPlugin {

	ofVideoGrabber * videoGrabber;
	ofTrueTypeFont * font;
	
	NSMutableArray * textArray;
	
	ofSoundPlayer * sound[2];
	
	IBOutlet NSTextField * currentTime;
	IBOutlet NSArrayController * arrayController;
	IBOutlet NSTextField * startTime;
	int currentLine;
	ofSerial * serial;
	NSDate * lastSerialDate;
	
	float setVolume[2];
	
	int mode;
	bool forceDuetStart;
	bool pause;
	
	IBOutlet NSTextField * modeLabel;
	IBOutlet NSTextField * pauseLabel;
}

-(IBAction) time:(id)sender;
-(IBAction) timeStop:(id)sender;
-(IBAction) duetStart:(id)sender;

@property (readwrite, retain) NSMutableArray * textArray;
@end
