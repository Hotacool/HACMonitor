//
//  HACNetwork.h
//  Pods
//
//  Created by macbook on 17/1/13.
//
//

#import "HACObject.h"
#import "HACNetworkInfo.h"
#import "HACNetworkFlow.h"

extern NSString *const kHACNetworkStatusUpdated;
extern NSString *const kHACNetworkExternalIPAddressUpdated;
@interface HACNetwork : HACObject

- (HACNetworkInfo*)getNetworkInfo;

+ (HACNetworkFlow*)getNetworkFlow ;

// 持续监控
- (BOOL)isActive ;

- (BOOL)startNetMonitorBlock:(void(^)(HACNetworkFlow *))block ;

- (void)stop ;
@end
