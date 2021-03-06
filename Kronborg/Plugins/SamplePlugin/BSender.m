#import "BSender.h"
#import "MTMessageBroker.h"
#import "MTMessage.h"
#import "AsyncSocket.h"

@interface BSender ()

@property (readwrite, retain) NSNetServiceBrowser *browser;
@property (readwrite, retain) NSMutableArray *services;
@property (readwrite, assign) BOOL isConnected;
@property (readwrite, retain) NSNetService *connectedService;
@property (readwrite, retain) MTMessageBroker *messageBroker;

@end


@implementation BSender

@synthesize browser;
@synthesize services;
@synthesize isConnected;
@synthesize connectedService;
@synthesize socket;
@synthesize messageBroker;
@synthesize receiverName;

-(id) init{
	if([super init]){
	    services = [NSMutableArray new];
		servicesController = [[NSArrayController alloc] initWithContent:services];
		self.isConnected = NO;	
	}
	return self;
}

-(void)dealloc {
	NSLog(@"Dealloc");
    self.connectedService = nil;
    self.browser = nil;
    //self.socket = nil;
    self.messageBroker.delegate = nil;
    self.messageBroker = nil;
    [services release];
    [super dealloc];
}

-(void)startSearchForType:(NSString*)type{
	NSAssert(self.browser == nil, @"You can only search once!");
	self.browser = [[[NSNetServiceBrowser alloc] init] autorelease];
    [self.browser setDelegate:self];
    [self.browser searchForServicesOfType:type inDomain:@""];
}

-(BOOL) receiverVisible:(NSString*)host{
	for(NSNetService * service in [servicesController content]){
		if([[service name] isEqualToString:host])
			return YES;
	}
	return NO;
}

-(void) sendStringMessage:(NSString*)msg tag:(int)tag{
	if(isConnected){		
		NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
		MTMessage *newMessage = [[[MTMessage alloc] init] autorelease];
		newMessage.tag = tag;
		newMessage.dataContent = data;
		[self.messageBroker sendMessage:newMessage];
	}
}

-(void) sendMessage:(id)value tag:(int)tag{
	if(isConnected){
		MTMessage *newMessage = [[[MTMessage alloc] init] autorelease];
		newMessage.tag = tag;
		[newMessage setValue:value];
		[self.messageBroker sendMessage:newMessage];
	}
}


/*
 -(void) updateStatus{
 BOOL ok = YES;
 NSMutableString * status = [NSMutableString string];
 for(NSString* host in monitorList){
 NSString * str = [NSString stringWithFormat:@"%@: ikke forbundet",host];
 BOOL found = NO;
 
 
 if([connectList containsObject:host]){
 if(self.isConnected){
 str = [NSString stringWithFormat:@"%@: forbundet",host];
 found = YES;
 } else {
 str = [NSString stringWithFormat:@"%@: Fejl, kan ikke forbinde",host];
 ok = NO;
 }
 } else {
 for(NSNetService * service in [servicesController content]){
 if([[service name] isEqualToString:host]){
 str = [NSString stringWithFormat:@"%@: OK.",host];
 found = YES;
 }
 }
 }		
 if(!found) ok = NO;
 
 [status appendFormat:@"%@\n\n", str];
 }	
 if(networkStatusText != nil)
 [networkStatusText setStringValue:status];
 
 if(networkStatusImage != nil){
 if(ok){
 [networkStatusImage setImage:[NSImage imageNamed:@"tick"]];	
 } else {
 [networkStatusImage setImage:[NSImage imageNamed:@"cross"]];	
 }	
 }
 }
 */

/*
#pragma mark AsyncSocket Delegate Methods

-(BOOL)onSocketWillConnect:(AsyncSocket *)sock {
//    if ( messageBroker == nil ) {
        [sock retain];
        return YES;
  //  }
    return NO;
}

-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {      
	NSLog(@"Connected to socket %@",host);
    MTMessageBroker *newBroker = [[[MTMessageBroker alloc] initWithAsyncSocket:socket] autorelease];
    [sock release];
    newBroker.delegate = self;
    self.messageBroker = newBroker;
    self.isConnected = YES;
}

*/

#pragma mark Net Service Browser Delegate Methods
-(void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didFindService:(NSNetService *)aService moreComing:(BOOL)more {
	NSLog(@"Found computer %@ on the network",[aService name]);
	if([receiverName isEqualToString:[aService name]]){
		[aService setDelegate:self];
		[aService resolveWithTimeout:0];
	}
    [servicesController addObject:aService];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didRemoveService:(NSNetService *)aService moreComing:(BOOL)more {
    [servicesController removeObject:aService];
	if([receiverName isEqualToString:[aService name]]){
		self.isConnected = NO;		
	}
}

-(void)netServiceDidResolveAddress:(NSNetService *)service {
	NSError *error;	
	NSLog(@"Connected bonjour to computer %@ on the network",[service name]);
    self.isConnected = YES;

    self.connectedService = service ;
/*	self.socket = [[[AsyncSocket alloc] initWithDelegate:self] autorelease];
    [self.socket connectToAddress:service.addresses.lastObject error:&error];		*/
}

-(void)netService:(NSNetService *)service didNotResolve:(NSDictionary *)errorDict {
	NSLog(@"ERROR: Could not connect to receiver");
}

@end