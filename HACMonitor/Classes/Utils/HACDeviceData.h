//
//  HACDeviceData.h
//  Pods
//
//  Created by macbook on 17/1/12.
//
//

#import <Foundation/Foundation.h>

@interface HACDeviceData : NSObject

+ (instancetype)sharedDeviceData;
- (void)setHwMachine:(NSString*)hwMachine;

- (const NSString*)getiDeviceName;
- (const NSString*)getCPUName;
- (NSUInteger)getCPUFrequency;
- (const NSString*)getRAMType;
- (NSUInteger)getBatteryCapacity;
- (CGFloat)getBatteryVoltage;
- (CGFloat)getScreenSize;
- (NSUInteger)getPPI;
- (NSString*)getAspectRatio;
@end
