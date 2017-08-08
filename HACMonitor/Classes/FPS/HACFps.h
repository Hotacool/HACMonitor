//
//  HACFps.h
//  Pods
//
//  Created by macbook on 17/1/16.
//
//

#import "HACObject.h"

typedef void(^HACFpsMonitorBlock)(CGFloat);

@interface HACFps : HACObject

- (BOOL)isActive ;

- (BOOL)startFpsMonitorBlock:(HACFpsMonitorBlock) block ;

- (void)stop ;
@end
