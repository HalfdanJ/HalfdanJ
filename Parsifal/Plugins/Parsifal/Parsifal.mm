//
//  Parsifal.mm
//  parsifal
//
//  Created by Jonas Jongejan on 29/03/11.
//  Copyright 2011 HalfdanJ. All rights reserved.
//
#import "VideoPlayer.h"
#import "Parsifal.h"


@implementation Parsifal
@synthesize textArray;

-(id) initPlugin{
	currentLine = -1;
	
	textArray = [NSMutableArray array];
	
	NSString * filepath = [@"~/Desktop/Parsifal/Undertekster.txt" stringByExpandingTildeInPath];
	NSString *file;
	NSArray *results;
	NSError * error;
	pause = NO;
	
	file = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
	//file = [file stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
	results = [file componentsSeparatedByString:@"\n"]; // Assumes Mac line end 'return'
	
	for(NSString * string in results){
		NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
		NSPredicate *noEmptyStrings = [NSPredicate predicateWithFormat:@"SELF != ''"];
		
		NSArray *parts = [string componentsSeparatedByCharactersInSet:whitespaces];
		NSArray *filteredArray = [parts filteredArrayUsingPredicate:noEmptyStrings];
		string = [filteredArray componentsJoinedByString:@" "];
		
		[textArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:string,@"text",nil]];
	}
	
	[self addObserver:self forKeyPath:@"customProperties" options:nil context:@"customProperties"];		
	lastSerialDate = [NSDate date];
	mode = 0;
	
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"BlomsterpigerVolume"];
	[self addProperty:[NumberProperty sliderPropertyWithDefaultvalue:1.0 minValue:0.0 maxValue:1.0] named:@"DuetVolume"];
	setVolume[0] = -1;
	setVolume[1] = -1;
}

-(IBAction) duetStart:(id)sender{
	forceDuetStart = YES;
}

-(int32_t) willDraw:(NSMutableDictionary *)drawingInformation{		
	if(forceDuetStart){
		mode = 4;
		sound[1]->play();
		if([startTime floatValue] > 0){
			sound[1]->setPosition([startTime floatValue]*1.0/(sound[1]->length/sound[1]->internalFreq));						
		}
		forceDuetStart = NO;
	}
	while(serial->available() > 0){
		int read = serial->readByte();
		cout<<read<<endl;
		if(-[lastSerialDate timeIntervalSinceNow] > 1){
			if(read == 5){
				mode ++;
				if(mode == 1){
				}else if(mode == 2){
					[[[GetPlugin(VideoPlayer) properties] objectForKey:@"video"] setIntValue:1];
				}
				else if(mode == 3){
					[[[GetPlugin(VideoPlayer) properties] objectForKey:@"video"] setIntValue:0];
					sound[0]->play();					
				}else if(mode == 4){
					[[[GetPlugin(VideoPlayer) properties] objectForKey:@"video"] setIntValue:0];
					sound[0]->stop();
					sound[1]->play();
					sound[1]->setPosition([startTime floatValue]*1.0/(sound[1]->length/sound[1]->internalFreq));
				} else {
					mode = 4;
					if([startTime floatValue] > 0){
						sound[1]->setPosition([startTime floatValue]*1.0/(sound[1]->length/sound[1]->internalFreq));						
					}
				}
				cout<<"Play"<<endl;		
				pause = NO;
			} 
			if(read == 7){
				if(pause){
					NSBeep();
					cout<<"Reset"<<endl;
					[[[GetPlugin(VideoPlayer) properties] objectForKey:@"video"] setIntValue:0];
					mode = 0;
					sound[0]->stop();
					sound[1]->stop();
					sound[1]->setPosition(0);
					currentLine = -1;
				} else {
					if(mode == 4){
						mode = 3;
					}
					cout<<"Stop"<<endl;
					[[[GetPlugin(VideoPlayer) properties] objectForKey:@"video"] setIntValue:0];
					//mode ++;
					sound[0]->stop();
					sound[1]->stop();
					sound[1]->setPosition(0);
					currentLine = -1;
					pause = YES;
				}
			}
			lastSerialDate = [NSDate date];
			
			return YES;
		}
	}
	
	
	if(mode > 0 && !pause){
		return YES;
	} else {
		return NO;
	}
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if(object == Prop(@"BlomsterpigerVolume")){
		setVolume[0] = [object floatValue];
	}
	if(object == Prop(@"DuetVolume")){
		setVolume[1] = [object floatValue];
	}
	
	if([(NSString*)context isEqualToString:@"customProperties"]){			
		NSArray * timingArray = [customProperties objectForKey:@"textTiming"] ;
		if(timingArray != nil){
			for(int i=0;i<[textArray count];i++){
				if([timingArray count] > i){
					NSMutableDictionary * dict = [textArray objectAtIndex:i];
					NSMutableDictionary * timing = [timingArray objectAtIndex:i]; 
					[dict setValue:[timing valueForKey:@"timing"] forKey:@"timing"];
					[dict setValue:[timing valueForKey:@"timingText"] forKey:@"timingText"];
				}
			}
			//		[self setTextArray:[customProperties valueForKey:@"textTiming"]];
		}
	}
}

-(NSMutableDictionary *) customProperties{
	//Read the settings of the selected cameras
	NSMutableDictionary * dict = customProperties;
	[dict setObject:textArray forKey:@"textTiming"];
	return dict;
}

-(void) setup{
	font = new ofTrueTypeFont();
	font->loadFont([[[NSBundle mainBundle] pathForResource:@"Trebuchet MS" ofType:@"ttf" inDirectory:@""] cString], 22, true, true, false);
	
	sound[0] = new ofSoundPlayer();
	sound[0]->loadSound([[@"~/Desktop/Parsifal/Blomsterpiger.wav" stringByExpandingTildeInPath] cString], YES);
	sound[1] = new ofSoundPlayer();
	sound[1]->loadSound([[@"~/Desktop/Parsifal/Duet.wav" stringByExpandingTildeInPath] cString], YES);
	
	//sound->play();
	
	
	serial = new ofSerial();
	
	BOOL serialOK =	serial->setup("/dev/tty.usbserial-A600agZC", 9600);
	cout<<"serial: "<<serialOK<<endl;
	
	videoGrabber = new ofVideoGrabber();
	videoGrabber->setDeviceID(7);
	videoGrabber->initGrabber(640, 480, true);
	
}



-(void) draw:(NSDictionary *)drawingInformation{
	if((mode == 1 || mode == 3 || mode == 4)&&!pause){
		ofSetColor(255, 255, 255,255);
		videoGrabber->draw(0, 0,1,1);
		glPushMatrix();
		
		//glTranslated(0, 1, 0);
		glScaled(1.0/720, 1.0/576, 1);
		
		if(mode == 4 && currentLine % 2  == 0 && currentLine >= 0 && [textArray count] > currentLine+1){
			NSDictionary * dict1 = [textArray objectAtIndex:currentLine];
			NSDictionary * dict2 = [textArray objectAtIndex:currentLine+1];
			
			string s[2];
			s[0] = [[dict1 valueForKey:@"text"] cStringUsingEncoding:NSISOLatin1StringEncoding];
			s[1] = [[dict2 valueForKey:@"text"] cStringUsingEncoding:NSISOLatin1StringEncoding];
			ofEnableAlphaBlending();
			int total = 2;
			if([[dict2 valueForKey:@"text"] length] == 0)
				total = 1;
			for(int i=0;i<total;i++){
				glPushMatrix();
				glTranslated(720*0.5, 576-(total-i)*38, 0);
				glScaled(0.9, 1.0, 1.0);
				float w = font->stringWidth(s[i]);
				ofSetColor(0, 0, 0, 100);
				ofRect(-w*0.5-7, -25, w+17, 35);
				
				ofSetColor(255, 255, 255);
				font->drawString(s[i], -w*0.5, 0);
				
				glPopMatrix();
			}	
			
		}
		
		
		
		glPopMatrix();
	}
	
}

-(NSTimeInterval) currentTime{
	return sound[1]->getPosition()*sound[1]->length/sound[1]->internalFreq;
}

-(NSString*) getStringFromTime:(double) time{
	int minutes = floor(time/60);
	int seconds = trunc(time - minutes * 60);
	int millis = trunc((time - (seconds + minutes * 60))*1000.0);
	
	NSString * _minutes = [NSString stringWithFormat:@"%i",minutes];
	if(minutes < 10)
		_minutes = [NSString stringWithFormat:@"0%i",minutes];
	
	NSString * _seconds = [NSString stringWithFormat:@"%i",seconds];
	if(seconds < 10)
		_seconds = [NSString stringWithFormat:@"0%i",seconds];
	
	NSString * _millis = [NSString stringWithFormat:@"%i",millis];
	if(millis < 100)
		_millis = [NSString stringWithFormat:@"0%i",millis];
	if(millis < 10)
		_millis = [NSString stringWithFormat:@"00%i",millis];
	
	return [NSString stringWithFormat:@"%@:%@.%@",_minutes,_seconds,_millis];
}

-(void) update:(NSDictionary *)drawingInformation{
	
	
	if(setVolume[0] >= 0){
		sound[0]->setVolume(setVolume[0]);
		setVolume[0] = -1;
	}
	if(setVolume[1] >= 0){
		sound[1]->setVolume(setVolume[1]);
		setVolume[1] = -1;
	}
	
	NSTimeInterval theTimeInterval = [self currentTime];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		if(pause){
			[pauseLabel setStringValue:@"JA"];
		} else 
			[pauseLabel setStringValue:@"NEJ"];
		
		[modeLabel setIntValue:mode];
		
	});
	dispatch_sync(dispatch_get_main_queue(), ^{
		
		[currentTime setStringValue:[self getStringFromTime:theTimeInterval]];
		
		
		int i = 0;
		
		for(NSMutableDictionary * dict in textArray){
			if(![[dict objectForKey:@"icon"] isEqualToString:@""])
				[dict setObject:@"" forKey:@"icon"];
			if([dict valueForKey:@"timing"] != nil){
				double val = [[dict valueForKey:@"timing"] doubleValue];
				if(val < [self currentTime])
					currentLine = i;
			}
			i++;
		}
		if(currentLine >= 0 && currentLine + 1 < [textArray count]){
			[[textArray objectAtIndex:currentLine] setObject:@"#####" forKey:@"icon"];
			[[textArray objectAtIndex:currentLine+1] setObject:@"#####" forKey:@"icon"];
		}
		
		
	});
	if(mode == 4 || mode == 1 || mode == 3)
		videoGrabber->update();
	
}

-(void) time:(id)sender{
	NSMutableDictionary * dict = [[arrayController selectedObjects] lastObject];
	[dict setObject:[NSNumber numberWithDouble:[self currentTime]] forKey:@"timing"];
	[dict setObject:[self getStringFromTime:[self currentTime]] forKey:@"timingText"];
	[arrayController selectNext:self];
	[arrayController selectNext:self];
	
}

-(void) timeStop:(id)sender{
	NSMutableDictionary * dict = [[arrayController selectedObjects] lastObject];
	int i = [textArray indexOfObject:dict];
	//	if(i > 1){
	if(i % 2 == 0)
		i ++;
	dict = [textArray objectAtIndex:i];
	[dict setObject:[NSNumber numberWithDouble:[self currentTime]] forKey:@"timing"];
	[dict setObject:[self getStringFromTime:[self currentTime]] forKey:@"timingText"];
	//}
	[arrayController selectNext:self];
	[arrayController selectNext:self];
}

@end
