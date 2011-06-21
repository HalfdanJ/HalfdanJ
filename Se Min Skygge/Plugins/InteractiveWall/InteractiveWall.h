#include "Plugin.h"
#include "Filter.h"
//#include "BlobTracker2d.h"
#include "Kinect.h"

//Todo 

struct bar {
    float val;
    Filter filter;
    float goal;
};

@interface InteractiveWall : ofPlugin {
    vector< bar > bars;
    vector< bar > bars2;

    bar leftBar, rightBar;
//    BlobTrackerInstance2d * tracker;
    KinectInstance * kinect;
}

@end
