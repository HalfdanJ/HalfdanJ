//
//  Kalibrering
//  SeMinSkygge
//  
//  ofxCocoaPlugins plugin
//  Created by Jonas Jongejan on 9/8/11.
//

#pragma once

#include "Plugin.h"

#import "ProjectorCalibrator.h"

@interface Kalibrering : ofPlugin{
    ProjectorCalibrator * projCalib[2];   
}

@end
