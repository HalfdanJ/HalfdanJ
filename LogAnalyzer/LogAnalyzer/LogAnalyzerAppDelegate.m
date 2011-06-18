//
//  LogAnalyzerAppDelegate.m
//  LogAnalyzer
//
//  Created by Jonas Jongejan on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LogAnalyzerAppDelegate.h"
#import "DDFileReader.h"

@implementation LogAnalyzerAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    
    array = [NSMutableArray array];
    for(int i=1;i<4;i++){
        [array addObject:[NSMutableArray array]];
        
        DDFileReader * reader = [[DDFileReader alloc] initWithFilePath:[NSString stringWithFormat:@"/Users/jonas/Dropbox/Kronborg/Globus/GlobusFælles/_globus%ilog.backup.log",i]];
        
        
        NSString * line = nil;
        
        NSMutableDictionary * dict = [NSMutableDictionary dictionary];
        
        NSInteger lastDay = -1;
        NSDate * lastDate = nil;
        NSString * lastRest = nil;
        
        int buttonPresses[12];
        int startups = 0;
        NSDate * firstBoot = nil;
        
        while ((line = [reader readLine])) {
            // NSLog(@"read line: %@", line);
            if([line length] > 25){
                NSDate * date = [NSDate dateWithString:[line substringToIndex:25]];
                
                NSDateComponents *weekdayComponents =
                [gregorian components:(NSDayCalendarUnit | NSWeekdayCalendarUnit) fromDate:date];
                NSInteger weekday = [weekdayComponents weekday];
                
                
                
                NSString * rest = [line substringFromIndex:27];
                // NSLog(@"%@",[rest substringFromIndex:12]);
                if([[rest substringToIndex:12] isEqualToString:@"Start video "]){
                    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                    [f setNumberStyle:NSNumberFormatterDecimalStyle];
                    NSNumber * myNumber = [f numberFromString:[rest substringWithRange:NSMakeRange(12, [rest length]-13)]];
                    buttonPresses[ [myNumber intValue] ]++;
                }
                if([[rest substringToIndex:1] isEqualToString:@"#"]){
                    startups++;
                }
                if([rest length]>25 && [[rest substringToIndex:20] isEqualToString:@"Computer boot time: "] && firstBoot == nil){
                    firstBoot = [NSDate dateWithString:[rest substringFromIndex:20]];
                }
                
                if(lastDay == -1 || weekday != lastDay ){
                    if(lastDay != -1){
                        for(int j=0;j<12;j++){
                            [dict setObject:[NSNumber numberWithInt:buttonPresses[j]] forKey:[NSString stringWithFormat:@"buttonPresses%i",j]];
                        }
                        [dict setObject:[NSNumber numberWithInt:startups] forKey:@"startups"];
                        
                        if(firstBoot != nil){
                            NSString * d = [firstBoot descriptionWithCalendarFormat:@"%m/%d/%Y %H:%M:%S" timeZone:nil locale:nil];
                            [dict setObject:d forKey:@"firstboot"];
                        } else {
                            [dict setObject:@"" forKey:@"firstboot"];
                        }
                        
                        
                        NSString * d = [lastDate descriptionWithCalendarFormat:@"%m/%d/%Y %H:%M:%S" timeZone:nil locale:nil];
                        [dict setObject:d forKey:@"shutdown"];
                        
                        if([[lastRest substringToIndex:1] isEqualToString:@"€"]){
                            [dict setObject:@"1" forKey:@"niceShutdown"];
                        } else {
                            [dict setObject:@"0" forKey:@"niceShutdown"];
                        }

                        
                        [[array objectAtIndex:i-1] addObject:dict];
                      //  NSLog(@"%@",dict);
                    }
                    
                    dict = [NSMutableDictionary dictionary];
                    NSString * d = [date descriptionWithCalendarFormat:@"%m/%d/%Y" timeZone:nil locale:nil];
                    [dict setObject:d forKey:@"dateDesc"];
                    [dict setObject:date forKey:@"date"];
                    
                    
                    for(int j=0;j<12;j++)
                        buttonPresses[j] = 0;
                    startups = 0;
                    firstBoot = nil;
                }
                
                lastDay = weekday;
                lastRest = rest;
                lastDate = date;
            }
        }        
    }
    
    

    
    
    NSLog(@"%i %i %i", [[array objectAtIndex:0] count],[[array objectAtIndex:1] count],[[array objectAtIndex:2] count]);

       
    
    
    
    
    
    
    for(int i=0;i<[[array objectAtIndex:0] count];i++){        
        NSMutableDictionary * defaultDict = [NSMutableDictionary dictionary];
        [defaultDict setValue:@"0" forKey:@"dateDesc"];
        [defaultDict setValue:@"0" forKey:@"startups"];
        [defaultDict setValue:@"0" forKey:@"firstboot"];
        [defaultDict setValue:@"0" forKey:@"shutdown"];
        [defaultDict setValue:@"0" forKey:@"niceShutdown"];
        
        for(int j=0;j<12;j++){
            [defaultDict setValue:@"0" forKey:[NSString stringWithFormat:@"buttonPresses%i",j]];
        }

        
        while([[array objectAtIndex:1] count] <= i){
            [[array objectAtIndex:1] addObject:defaultDict ]; 
        }
        while([[array objectAtIndex:2] count] <= i){
            [[array objectAtIndex:2] addObject:defaultDict]; 
        }
        
        NSDate * date1 = [[[array objectAtIndex:0] objectAtIndex:i] objectForKey:@"date"];
        NSDate * date2 = [[[array objectAtIndex:1] objectAtIndex:i] objectForKey:@"date"];
        NSDate * date3 = [[[array objectAtIndex:2] objectAtIndex:i] objectForKey:@"date"];
        
        NSDateComponents *weekdayComponents = [gregorian components:(NSWeekdayCalendarUnit) fromDate:date1];
        NSInteger weekday1 = [weekdayComponents weekday];
        weekdayComponents = [gregorian components:(NSWeekdayCalendarUnit) fromDate:date2];
        NSInteger weekday2 = [weekdayComponents weekday];
        weekdayComponents = [gregorian components:(NSWeekdayCalendarUnit) fromDate:date3];
        NSInteger weekday3 = [weekdayComponents weekday];
        
        if(weekday1 == weekday2 && weekday1 == weekday3){
            NSLog(@"Yay");
        } else {
            NSLog(@"påroblem");

            while(weekday1%7 > weekday2%7 && [date1 compare:date2] == NSOrderedDescending){
                [[array objectAtIndex:0] insertObject:defaultDict atIndex:i];
                weekday1 --;
            }
            while(weekday1%7 > weekday3%7 && [date1 compare:date3] == NSOrderedDescending){
                [[array objectAtIndex:0] insertObject:defaultDict atIndex:i];
                weekday1 --;                
            }
            while(weekday2%7 > weekday1%7 && [date2 compare:date1] == NSOrderedDescending){
                [[array objectAtIndex:1] insertObject:defaultDict atIndex:i];
                weekday2 --;                
            }
            while(weekday2%7 > weekday3%7 && [date2 compare:date3] == NSOrderedDescending){
                [[array objectAtIndex:1] insertObject:defaultDict atIndex:i];
                weekday2 --;                
            }
            while(weekday3%7 > weekday1%7 && [date3 compare:date1] == NSOrderedDescending){
                [[array objectAtIndex:2] insertObject:defaultDict atIndex:i];
                weekday3 --;                
            }
            while(weekday3%7 > weekday2%7 && [date3 compare:date2] == NSOrderedDescending){
                [[array objectAtIndex:3] insertObject:defaultDict atIndex:i];
                weekday3 --;                
            }

        }
    }

    
    
    NSFileHandle *output = [NSFileHandle fileHandleForWritingAtPath:@"/Users/jonas/Desktop/csv/output.csv"];
    [output seekToEndOfFile];
    
    NSMutableString * string = [NSMutableString stringWithFormat:@"date,"];
    
    [string appendFormat:@"num. starts 1,"];
    [string appendFormat:@"num. starts 2,"];
    [string appendFormat:@"num. starts 3,"];
    [string appendFormat:@"boot time 1,"];
    [string appendFormat:@"boot time 2,"];
        [string appendFormat:@"boot time 3,"];
    [string appendFormat:@"shutdown time 1,"];
    [string appendFormat:@"shutdown time 2,"];
    [string appendFormat:@"shutdown time 3,"];
    [string appendFormat:@"nice shutown 1,"];    
    [string appendFormat:@"nice shutown 2,"];    
    [string appendFormat:@"nice shutown 3,"];    
    for(int j=0;j<12;j++){
        [string appendFormat:@"%i plays 1,",j];
        [string appendFormat:@"%i plays 2,",j];
        [string appendFormat:@"%i plays 3,",j];
    }
    
    [string appendFormat:@"\n"];
    
    [output writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    

    
    NSLog(@"%i %i %i", [[array objectAtIndex:0] count],[[array objectAtIndex:1] count],[[array objectAtIndex:2] count]);
    
    
    int i=0;
    for(NSMutableDictionary * dict1 in [array objectAtIndex:0]){
        NSDictionary * dict2 = [[array objectAtIndex:1] objectAtIndex:i];
        NSDictionary * dict3 = [[array objectAtIndex:2] objectAtIndex:i];                                  
        NSMutableString * string;
        if(![[dict1 objectForKey:@"dateDesc"] isEqualToString:@"0"])
            string = [NSMutableString stringWithFormat:@"%@,", [dict1 objectForKey:@"dateDesc"]];
        else if(![[dict2 objectForKey:@"dateDesc"] isEqualToString:@"0"])
            string = [NSMutableString stringWithFormat:@"%@,", [dict2 objectForKey:@"dateDesc"]];
        else 
            string = [NSMutableString stringWithFormat:@"%@,", [dict3 objectForKey:@"dateDesc"]];
        
        [string appendFormat:@"%@,",[dict1 objectForKey:@"startups"]];
        [string appendFormat:@"%@,",[dict2 objectForKey:@"startups"]];
        [string appendFormat:@"%@,",[dict3 objectForKey:@"startups"]];
        [string appendFormat:@"%@,",[dict1 objectForKey:@"firstboot"]];
        [string appendFormat:@"%@,",[dict2 objectForKey:@"firstboot"]];       
        [string appendFormat:@"%@,",[dict3 objectForKey:@"firstboot"]];
        [string appendFormat:@"%@,",[dict1 objectForKey:@"shutdown"]];
        [string appendFormat:@"%@,",[dict2 objectForKey:@"shutdown"]];        
        [string appendFormat:@"%@,",[dict3 objectForKey:@"shutdown"]];        
        [string appendFormat:@"%@,",[dict1 objectForKey:@"niceShutdown"]];
        [string appendFormat:@"%@,",[dict2 objectForKey:@"niceShutdown"]];
        [string appendFormat:@"%@,",[dict3 objectForKey:@"niceShutdown"]];
        
        for(int j=0;j<12;j++){
            [string appendFormat:@"%@,",[dict1 objectForKey:[NSString stringWithFormat:@"buttonPresses%i",j]]];
            [string appendFormat:@"%@,",[dict2 objectForKey:[NSString stringWithFormat:@"buttonPresses%i",j]]];
            [string appendFormat:@"%@,",[dict3 objectForKey:[NSString stringWithFormat:@"buttonPresses%i",j]]];
        }
        
        [string appendFormat:@"\n"];
        
        [output writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
        
        i++;
    }
    
}

@end
