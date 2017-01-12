//
//  HACRamInfo.h
//  Pods
//
//  Created by macbook on 17/1/12.
//
//

#import "HACObject.h"

@interface HACRamInfo : HACObject

@property (nonatomic, assign) uint64_t  totalRam;
@property (nonatomic, copy)   NSString  *ramType;

@property (nonatomic, assign) uint64_t usedRam;
@property (nonatomic, assign) uint64_t activeRam;
@property (nonatomic, assign) uint64_t inactiveRam;
@property (nonatomic, assign) uint64_t wiredRam;
@property (nonatomic, assign) uint64_t freeRam;
@property (nonatomic, assign) uint64_t pageIns;
@property (nonatomic, assign) uint64_t pageOuts;
@property (nonatomic, assign) uint64_t pageFaults;
@end
