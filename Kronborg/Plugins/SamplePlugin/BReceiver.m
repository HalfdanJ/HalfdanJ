#import "BReceiver.h"
#import "AsyncSocket.h"
#import "MTMessageBroker.h"
#import "MTMessage.h"

@interface BReceiver ()
@property (readwrite, retain) MTMessageBroker *messageBroker;

-(void)startService;
-(void)stopService;

@end



@implementation BReceiver

@synthesize delegate;
@synthesize listeningSocket;
@synthesize connectionSocket;
@synthesize messageBroker;

-(id) initWithType:(NSString*)_type{
	if([self init]){
		type= _type;
		[self startService];	
	}
	return self;
}

-(void)startService {
	NSError *error;
//	self.listeningSocket = [[[AsyncSocket alloc]initWithDelegate:self] autorelease];
/*	if ( ![self.listeningSocket acceptOnPort:0 error:&error] ) {
		NSLog(@"Failed to create listening socket");
		return;
	}
*/	
	
	NSLog(@"Start service");
	netService = [[NSNetService alloc] initWithDomain:@"" type:type 
												 name:@"Globus" port:self.listeningSocket.localPort];
	
    netService.delegate = self;
    [netService publish];
}

-(void)stopService {
//    self.listeningSocket = nil;
  //  self.connectionSocket = nil;
    self.messageBroker.delegate = nil;
    self.messageBroker = nil;
    [netService stop]; 
    [netService release];    
    [super dealloc];
}

-(void)dealloc {
    [self stopService];
    [super dealloc];
}


/*#pragma mark Socket Callbacks
-(BOOL)onSocketWillConnect:(AsyncSocket *)sock {
	NSLog(@"Sender connected");
   // if ( self.connectionSocket == nil ) {
        self.connectionSocket = sock;
        return YES;
    //}
    return NO;
}
-(void) onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError*)err{
//	NSLog(@"will clean disconnect");
}
-(void)onSocketDidDisconnect:(AsyncSocket *)sock {
//	NSLog(@"Will disconnect");
    if ( sock == self.connectionSocket ) {
        self.connectionSocket = nil;
        self.messageBroker = nil;
    }
}
-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    MTMessageBroker *newBroker = [[[MTMessageBroker alloc] initWithAsyncSocket:sock] autorelease];
    newBroker.delegate = self;
    self.messageBroker = newBroker;
}
*/

#pragma mark MTMessageBroker Delegate Methods
-(void)messageBroker:(MTMessageBroker *)server didReceiveMessage:(MTMessage *)message {
	
	// textView.string = [[[NSString alloc] initWithData:message.dataContent encoding:NSUTF8StringEncoding] autorelease];
	if([message type] == 1){
		if(delegate != nil){
			[delegate receiveStringMessage:[[[NSString alloc] initWithData:message.dataContent encoding:NSUTF8StringEncoding] autorelease] tag:[message tag]];
		}
	}
	
	[delegate receiveMessage:[message value] tag:[message tag]];
	
}


#pragma mark Net Service Delegate Methods
-(void)netService:(NSNetService *)aNetService didNotPublish:(NSDictionary *)dict {
    NSLog(@"Failed to publish: %@", dict);
}



@end
