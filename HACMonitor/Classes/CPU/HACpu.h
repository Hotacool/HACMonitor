//
//  HACpu.h
//  Pods
//
//  Created by macbook on 17/1/12.
//
//

#import "HACObject.h"
#import "HACpuInfo.h"
#import "HACpuLoad.h"

@interface HACpu : HACObject

/**
 *  获取CPU基本信息
 *
 *  @return cpu information
 */
- (HACpuInfo*)getCpuInfo ;

/**
 *  获取APP占用系统CPU百分比
 *
 *  @return cpu usage for current task
 */
+ (CGFloat)getCpuUsageForTaskSelf ;

/**
 *  获取系统所有进程使用CPU百分比，即当前系统CPU使用量
 *
 *  @return cpu usage
 */
- (NSArray<HACpuLoad*>*)getCpuUsageForAllProcessors ;

@end
