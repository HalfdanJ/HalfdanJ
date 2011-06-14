#import <Cocoa/Cocoa.h>

@class AsyncSocket;
@class MTMessageBroker;

@interface BSender : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate> {
    BOOL isConnected;
    
	NSNetServiceBrowser *browser;
    NSNetService *connectedService;
    NSMutableArray *services;
    NSArrayController *servicesController;
		
	AsyncSocket *socket;
    MTMessageBroker *messageBroker;
	
	NSString * receiverName;
	
}

@property (readonly, retain) NSMutableArray *services;
@property (readonly, assign) BOOL isConnected;
@property (readwrite, retain) AsyncSocket *socket;
@property (readwrite, retain) NSString * receiverName;

-(void)startSearchForType:(NSString*)type;
-(BOOL) receiverVisible:(NSString*)host;

-(void) sendStringMessage:(NSString*)msg tag:(int)tag;
-(void) sendMessage:(id)value tag:(int)tag;
@end