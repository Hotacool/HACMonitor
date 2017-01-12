//
//  HACpuInfo.h
//  Pods
//
//  Created by macbook on 17/1/12.
//
//

#import "HACObject.h"

@interface HACpuInfo : HACObject
@property (nonatomic, copy)   NSString     *cpuName;
@property (nonatomic, assign) NSUInteger   activeCPUCount;
@property (nonatomic, assign) NSUInteger   physicalCPUCount;
@property (nonatomic, assign) NSUInteger   physicalCPUMaxCount;
@property (nonatomic, assign) NSUInteger   logicalCPUCount;
@property (nonatomic, assign) NSUInteger   logicalCPUMaxCount;
@property (nonatomic, assign) NSUInteger   cpuFrequency;
@property (nonatomic, assign) NSUInteger   l1DCache;
@property (nonatomic, assign) NSUInteger   l1ICache;
@property (nonatomic, assign) NSUInteger   l2Cache;
@property (nonatomic, copy)   NSString     *cpuType;
@property (nonatomic, copy)   NSString     *cpuSubtype;
@property (nonatomic, copy)   NSString     *endianess;
@end
