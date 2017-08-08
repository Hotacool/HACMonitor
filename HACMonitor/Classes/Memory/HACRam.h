//
//  HACRaw.h
//  Pods
//
//  Created by macbook on 17/1/12.
//
//

#import "HACObject.h"
#import "HACRamInfo.h"

@interface HACRam : HACObject

/**
 *  获取内存整体信息
 *
 *  @return ram information
 */
+ (HACRamInfo*)getRamInfo ;

/**
 *  获取当前App使用内存
 *
 *  @return ram used, byte
 */
+ (CGFloat)getUsedMemory ;

// 持续监控
- (BOOL)isActive ;

- (BOOL)startRamMonitorBlock:(void(^)(CGFloat))block ;

- (void)stop ;
@end
