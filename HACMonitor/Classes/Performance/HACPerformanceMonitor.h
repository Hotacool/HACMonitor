//
//  HACPerformanceMonitor.h
//  HACMonitor
//
//  Created by Hotacool on 2017/7/21.
//

#import <Foundation/Foundation.h>

@interface HACPerformanceMonitor : NSObject

+ (instancetype)sharedInstance;

- (void)start;
- (void)stop;
@end
