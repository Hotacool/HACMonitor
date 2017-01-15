//
//  HACNetworkFlow.h
//  Pods
//
//  Created by silver on 2017/1/15.
//
//

#import "HACObject.h"

@interface HACNetworkFlow : HACObject
@property (nonatomic, assign) NSUInteger allFlow;
@property (nonatomic, assign) NSUInteger inBytes;
@property (nonatomic, assign) NSUInteger outBytes;

@property (nonatomic, assign) NSUInteger wifiFlow;
@property (nonatomic, assign) NSUInteger wifiInBytes;
@property (nonatomic, assign) NSUInteger wifiOutBytes;

@property (nonatomic, assign) NSUInteger wwanFlow;
@property (nonatomic, assign) NSUInteger wwanInBytes;
@property (nonatomic, assign) NSUInteger wwanOutBytes;

@property (nonatomic, assign) long lastChangeTime;
@end
