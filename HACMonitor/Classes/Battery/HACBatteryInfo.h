//
//  HACBatteryInfo.h
//  Pods
//
//  Created by macbook on 17/1/13.
//
//

#import "HACObject.h"

typedef NS_ENUM(NSUInteger, HACBatteryStatus) {
    HACBatteryStatusUnknow,
    HACBatteryStatusFully,
    HACBatteryStatusCharging,
    HACBatteryStatusUnplugged
};

@interface HACBatteryInfo : HACObject
@property (nonatomic, assign) NSUInteger    capacity;
@property (nonatomic, assign) CGFloat       voltage;

@property (nonatomic, assign) NSUInteger    levelPercent;
@property (nonatomic, assign) NSUInteger    levelMAH;
@property (nonatomic, assign) HACBatteryStatus status;
@end
