//
//  HACNetworkInfo.h
//  Pods
//
//  Created by macbook on 17/1/13.
//
//

#import "HACObject.h"

@interface HACNetworkInfo : HACObject
@property (nonatomic, copy) NSString  *readableInterface;
@property (nonatomic, copy) NSString  *externalIPAddress;
@property (nonatomic, copy) NSString  *internalIPAddress;
@property (nonatomic, copy) NSString  *netmask;
@property (nonatomic, copy) NSString  *broadcastAddress;
@end
