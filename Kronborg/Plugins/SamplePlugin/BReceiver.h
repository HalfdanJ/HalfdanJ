#import <Cocoa/Cocoa.h>

@class AsyncSocket;
@class MTMessageBroker;

@protocol BReceiverDelegate
-(void) receiveStringMessage:(NSString*)message tag:(int)tag;
-(void) receiveMessage:(id)message tag:(int)tag;


@end


@interface BReceiver : NSObject <NSNetServiceDelegate> {
    NSNetService *netService;

	AsyncSocket *listeningSocket;
    AsyncSocket *connectionSocket;
    MTMessageBroker *messageBroker;
	
	NSString* type;
	
	id<BReceiverDelegate> delegate;
}

-(id) initWithType:(NSString*)type;

@property (readwrite, retain) AsyncSocket *listeningSocket;
@property (readwrite, retain) AsyncSocket *connectionSocket;
@property (readwrite, retain) id<BReceiverDelegate> delegate;

@end
