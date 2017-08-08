//
//  HACMonitorManager.h
//  HACMonitor
//
//  Created by Hotacool on 2017/8/7.
//

#import <Foundation/Foundation.h>

@interface HACMonitorManager : NSObject
+ (instancetype)shareInstance ;

- (void)showHoverButton ;

- (void)dismissHoverButton ;
@end
