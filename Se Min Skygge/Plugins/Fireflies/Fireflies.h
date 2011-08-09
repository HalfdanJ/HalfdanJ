#pragma once

#include "Plugin.h"

#import "Keystoner.h"
#import "Kinect.h"


@interface Fireflies : ofPlugin{
    KinectInstance * kinect;
    KeystoneSurface * surface;

}

@end
