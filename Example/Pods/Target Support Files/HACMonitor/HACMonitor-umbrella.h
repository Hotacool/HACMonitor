#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "HACBattery.h"
#import "HACBatteryInfo.h"
#import "HACpu.h"
#import "HACpuInfo.h"
#import "HACpuLoad.h"
#import "HACFps.h"
#import "HACRam.h"
#import "HACRamInfo.h"
#import "HACNetwork.h"
#import "HACNetworkFlow.h"
#import "HACNetworkInfo.h"
#import "HACPerformanceMonitor.h"
#import "AMUtils.h"
#import "HACDeviceData.h"
#import "HACHelp.h"
#import "HACObject.h"
#import "HACWeakObject.h"

FOUNDATION_EXPORT double HACMonitorVersionNumber;
FOUNDATION_EXPORT const unsigned char HACMonitorVersionString[];

