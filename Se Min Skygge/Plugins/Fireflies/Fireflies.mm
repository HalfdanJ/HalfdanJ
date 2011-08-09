
#import "Fireflies.h"

@implementation Fireflies

-(void)initPlugin{
  
}

-(void)setup{
    [self assignMidiChannel:11]; 
    kinect = [GetPlugin(Kinect) getInstance:1];
    surface = [GetPlugin(Keystoner) getSurface:@"Screen" viewNumber:0 projectorNumber:0];
    
    
    
}

@end
