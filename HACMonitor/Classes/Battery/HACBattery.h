//
//  HACBattery.h
//  Pods
//
//  Created by macbook on 17/1/13.
//
//

#import "HACObject.h"
#import "HACBatteryInfo.h"

@interface HACBattery : HACObject

- (HACBatteryInfo*)getBatteryInfo ;
#pragma mark - 方法一
- (void)startBatteryMonitoring ;

- (void)stopBatteryMonitoring ;

- (BOOL)isMonitorEnable ;

#pragma mark - 方法三
+ (int)getCurrentBatteryLevel ;
@end
