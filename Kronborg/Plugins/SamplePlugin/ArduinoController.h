//
//  ArduinoController.h
//  kronborg
//
//  Created by Jonas Jongejan on 21/09/10.
//  Copyright 2010 HalfdanJ. All rights reserved.
//

#include "Plugin.h"

enum ArduinoPropertyType {
	ArduinoTypeIntArray = 1
};

enum ArduinoPropertyDirection {
	ArduinoReceive = 128
};


@interface ArduinoController : NSObject {
	NSThread * thread;
	pthread_mutex_t mutex;
	
	bool inCommandProcess;
	int commandInProcess;
	int typeInProcess;
	ofSerial * serial;
	
	bool connected, ok;
	int timeout;
	
	vector<unsigned char> * serialBuffer;
	
	NSMutableDictionary * properties;
	
	id delegate;
	
}
-(void) setDelegate:(id)_delegate;

-(void) setup;
-(void) update;

-(BOOL) connected;

-(NSArray*) propertyKeys;
-(NSMutableDictionary *) property:(int)tag;
-(NSString *) propertyKey:(int)tag;
@end
