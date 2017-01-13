//
//  HACBattery.m
//  Pods
//
//  Created by macbook on 17/1/13.
//
//

#import "HACBattery.h"
#import "HACHelp.h"
#import "HACDeviceData.h"
#import <objc/runtime.h>

@implementation HACBattery {
    HACBatteryInfo *batteryInfo;
    BOOL monitorEnable;
}

- (HACBatteryInfo*)getBatteryInfo {
    if (HACObjectIsNull(batteryInfo)) {
        batteryInfo = [[HACBatteryInfo alloc] init];
    }
    batteryInfo.capacity = [self getBatteryCapacity];
    batteryInfo.voltage = [self getBatteryVoltage];
    return batteryInfo;
}

#pragma mark -- get battery usage
#pragma mark - 方法一: 官方文档，偏差1%左右
- (void)startBatteryMonitoring {
    if (![self isMonitorEnable]) {
        UIDevice *device = [UIDevice currentDevice];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(doUpdateBatteryStatus)
                                                     name:UIDeviceBatteryLevelDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(doUpdateBatteryStatus)
                                                     name:UIDeviceBatteryStateDidChangeNotification
                                                   object:nil];
        
        [device setBatteryMonitoringEnabled:YES];
        monitorEnable = YES;
        
        // If by any chance battery value is available - update it immediately
        if ([device batteryState] != UIDeviceBatteryStateUnknown)
        {
            [self doUpdateBatteryStatus];
        }
    }
}

- (void)stopBatteryMonitoring {
    if ([self isMonitorEnable]) {
        [[UIDevice currentDevice] setBatteryMonitoringEnabled:NO];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        monitorEnable = NO;
    }
}

- (BOOL)isMonitorEnable {
    return monitorEnable;
}

#pragma mark - 方法二: 偏差，不精确，需要引入Mac下IOKit.framework
/**
 *  Calculating the remaining energy
 *
 *  @return Current batterylevel
 */
/*
 
-(double)getCurrentBatteryLevel
{
    
    //Returns a blob of Power Source information in an opaque CFTypeRef.
    CFTypeRef blob = IOPSCopyPowerSourcesInfo();
    
    //Returns a CFArray of Power Source handles, each of type CFTypeRef.
    CFArrayRef sources = IOPSCopyPowerSourcesList(blob);
    
    CFDictionaryRef pSource = NULL;
    const void *psValue;
    
    //Returns the number of values currently in an array.
    int numOfSources = CFArrayGetCount(sources);
    
    //Error in CFArrayGetCount
    if (numOfSources == 0)
    {
        NSLog(@"Error in CFArrayGetCount");
        return -1.0f;
    }
    
    //Calculating the remaining energy
    for (int i = 0 ; i < numOfSources ; i++)
    {
        //Returns a CFDictionary with readable information about the specific power source.
        pSource = IOPSGetPowerSourceDescription(blob, CFArrayGetValueAtIndex(sources, i));
        if (!pSource)
        {
            NSLog(@"Error in IOPSGetPowerSourceDescription");
            return -1.0f;
        }
        psValue = (CFStringRef)CFDictionaryGetValue(pSource, CFSTR(kIOPSNameKey));
        
        int curCapacity = 0;
        int maxCapacity = 0;
        double percent;
        
        psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSCurrentCapacityKey));
        CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &curCapacity);
        
        psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSMaxCapacityKey));
        CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &maxCapacity);
        
        percent = ((double)curCapacity/(double)maxCapacity * 100.0f);  
        
        return percent;  
    }  
    return -1.0f;  
}
 
*/

#pragma mark - 方法三: 通过runtime 获取StatusBar上电池电量控件类私有变量的值，此方法可精准获取iOS6以上电池电量
+ (int)getCurrentBatteryLevel {
    UIApplication *app = [UIApplication sharedApplication];
    if (app.applicationState == UIApplicationStateActive||app.applicationState==UIApplicationStateInactive) {
        Ivar ivar=  class_getInstanceVariable([app class],"_statusBar");
        id status  = object_getIvar(app, ivar);
        for (id aview in [status subviews]) {
            int batteryLevel = 0;
            for (id bview in [aview subviews]) {
                if ([NSStringFromClass([bview class]) caseInsensitiveCompare:@"UIStatusBarBatteryItemView"] == NSOrderedSame&&[[[UIDevice currentDevice] systemVersion] floatValue] >=6.0)
                {
                    Ivar ivar=  class_getInstanceVariable([bview class],"_capacity");
                    if(ivar)
                    {
                        batteryLevel = ((int (*)(id, Ivar))object_getIvar)(bview, ivar);
                        //这种方式也可以
                        /*ptrdiff_t offset = ivar_getOffset(ivar);
                         unsigned char *stuffBytes = (unsigned char *)(__bridge void *)bview;
                         batteryLevel = * ((int *)(stuffBytes + offset));*/
                        NSLog(@"电池电量:%d",batteryLevel);
                        if (batteryLevel > 0 && batteryLevel <= 100) {
                            return batteryLevel;
                        } else {
                            return 0;
                        }
                    }
                }
            }
        }
    }
    
    return 0;
}


#pragma mark - private
- (void)doUpdateBatteryStatus {
    if (HACObjectIsNull(batteryInfo)) {
        batteryInfo = [[HACBatteryInfo alloc] init];
    }
    float batteryMultiplier = [[UIDevice currentDevice] batteryLevel];
    batteryInfo.levelPercent = batteryMultiplier * 100;
    batteryInfo.levelMAH =  batteryInfo.capacity * batteryMultiplier;
    
    switch ([[UIDevice currentDevice] batteryState]) {
        case UIDeviceBatteryStateCharging:
            // UIDeviceBatteryStateFull seems to be overwritten by UIDeviceBatteryStateCharging
            // when charging therefore it's more reliable if we check the battery level here
            // explicitly.
            if (batteryInfo.levelPercent == 100)
            {
                batteryInfo.status = HACBatteryStatusFully;
            }
            else
            {
                batteryInfo.status = HACBatteryStatusCharging;
            }
            break;
        case UIDeviceBatteryStateFull:
            batteryInfo.status = HACBatteryStatusFully;
            break;
        case UIDeviceBatteryStateUnplugged:
            batteryInfo.status = HACBatteryStatusUnplugged;
            break;
        case UIDeviceBatteryStateUnknown:
            batteryInfo.status = HACBatteryStatusUnknow;
            break;
    }
}

- (NSUInteger)getBatteryCapacity
{
    HACDeviceData *hardcode = [HACDeviceData sharedDeviceData];
    return [hardcode getBatteryCapacity];
}

- (CGFloat)getBatteryVoltage
{
    HACDeviceData *hardcode = [HACDeviceData sharedDeviceData];
    return [hardcode getBatteryVoltage];
}

@end
