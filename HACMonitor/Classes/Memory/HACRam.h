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
 *  获取内存基本信息
 *
 *  @return ram information
 */
+ (HACRamInfo*)getRamInfo ;

/**
 *  获取内存使用情况
 *
 *  @return ram usage information
 */
+ (HACRamInfo*)getRAMUsage ;

/**
 *  获取当前App使用内存
 *
 *  @return ram used, byte
 */
+ (CGFloat)getUsedMemory ;
@end
