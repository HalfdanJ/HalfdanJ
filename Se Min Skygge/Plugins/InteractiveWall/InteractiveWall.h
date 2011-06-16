#include "Plugin.h"
#include "Filter.h"
//#include "BlobTracker2d.h"
#include "Kinect.h"

struct bar {
    float val;
    Filter filter;
    float goal;
};

@interface InteractiveWall : ofPlugin {
    vector< bar > bars;
//    BlobTrackerInstance2d * tracker;
    KinectInstance * kinect;
}

@end
