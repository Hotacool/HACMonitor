//
//  HACNetwork.h
//  Pods
//
//  Created by macbook on 17/1/13.
//
//

#import "HACObject.h"
#import "HACNetworkInfo.h"

extern NSString *const kHACNetworkStatusUpdated;
extern NSString *const kHACNetworkExternalIPAddressUpdated;
@interface HACNetwork : HACObject

- (HACNetworkInfo*)getNetworkInfo;
@end
