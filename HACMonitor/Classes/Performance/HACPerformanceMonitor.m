//
//  HACPerformanceMonitor.m
//  HACMonitor
//
//  Created by Hotacool on 2017/7/21.
//

#import "HACPerformanceMonitor.h"

@implementation HACPerformanceMonitor {
    int timeoutCount;
    CFRunLoopObserverRef observer;
    dispatch_semaphore_t semaphore;
    CFRunLoopActivity activity;
}

+ (instancetype)sharedInstance {
    static HACPerformanceMonitor *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HACPerformanceMonitor alloc] init];
    });
    return instance;
}

- (void)stop {
    if (!observer) {
        return;
    }
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
    CFRelease(observer);
    observer = NULL;
}

- (void)start {
    if (observer) {
        return;
    }
    // 信号
    semaphore = dispatch_semaphore_create(0);
    
    // 注册RunLoop状态观察
    CFRunLoopObserverContext context = {0,(__bridge void*)self,NULL,NULL};
    observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                       kCFRunLoopAllActivities,
                                       YES,
                                       0,
                                       &runLoopObserverCallBack,
                                       &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
    
    // 在子线程监控时长
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (YES) {
            long st = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 20*NSEC_PER_MSEC));
            if (st != 0) {
                if (!observer) {
                    timeoutCount = 0;
                    semaphore = 0;
                    activity = 0;
                    return;
                }
                
                if (activity==kCFRunLoopBeforeSources || activity==kCFRunLoopAfterWaiting) {
                    if (++timeoutCount < 5) {
                        continue;
                    }
                    //卡顿🛡🛡🛡
                    NSLog(@"卡顿了...");
                }
            }
            timeoutCount = 0;
        }
    });
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    HACPerformanceMonitor *moniotr = (__bridge HACPerformanceMonitor*)info;
    moniotr->activity = activity;
    dispatch_semaphore_t semaphore = moniotr->semaphore;
    dispatch_semaphore_signal(semaphore);
}
@end
