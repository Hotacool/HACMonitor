//
//  HACMonitorManager.m
//  HACMonitor
//
//  Created by Hotacool on 2017/8/7.
//

#import "HACMonitorManager.h"
#import "HACHoverButton.h"
#import "HACFps.h"
#import "HACRam.h"
#import "HACpu.h"
#import "HACNetwork.h"

@interface HACMonitorManager ()
@property (nonatomic, strong) HACFps *fpsMonitor;
@property (nonatomic, strong) HACRam *ramMonitor;
@property (nonatomic, strong) HACpu *cpuMonitor;
@property (nonatomic, strong) HACNetwork *netMonitor;
@end

@implementation HACMonitorManager {
    HACHoverButton *_hoverButton;
}

+ (instancetype)shareInstance {
    static HACMonitorManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [HACMonitorManager new];
    });
    return instance;
}

- (void)showHoverButton {
    if (!_hoverButton) {
        _hoverButton = [[HACHoverButton alloc] init];
        [_hoverButton setItemArray:@[@"CPU",@"内存", @"下载", @"上传",@"FPS"]];
    }
    [_hoverButton show];
    
    [self startMonitor];
}

- (void)dismissHoverButton {
    [_hoverButton dismiss];
    [self stopMonitor];
}

- (void)startMonitor {
    if (![self.fpsMonitor isActive]) {
        __weak typeof(self) weakSelf = self;
        [self.fpsMonitor startFpsMonitorBlock:^(CGFloat value) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf->_hoverButton refreshButtonAtIndex:4 withBlock:^(UIButton *button) {
                    [button setTitle:[NSString stringWithFormat:@"%.0ffps", value] forState:UIControlStateNormal];
                }];
            });
        }];
    }
    if (![self.ramMonitor isActive]) {
        __weak typeof(self) weakSelf = self;
        [self.ramMonitor startRamMonitorBlock:^(CGFloat value) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf->_hoverButton refreshButtonAtIndex:1 withBlock:^(UIButton *button) {
                    [button setTitle:[NSString stringWithFormat:@"%.2fMB", value] forState:UIControlStateNormal];
                }];
            });
        }];
    }
    if (![self.cpuMonitor isActive]) {
        __weak typeof(self) weakSelf = self;
        [self.cpuMonitor startCpuMonitorBlock:^(CGFloat value) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf->_hoverButton refreshButtonAtIndex:0 withBlock:^(UIButton *button) {
                    [button setTitle:[NSString stringWithFormat:@"%.2f%%", value] forState:UIControlStateNormal];
                }];
            });
        }];
    }
    if (![self.netMonitor isActive]) {
        __weak typeof(self) weakSelf = self;
        [self.netMonitor startNetMonitorBlock:^(HACNetworkFlow *networkFlow) {
            float download = (float)networkFlow.inBytes/1024/1024;
            float upload = (float)networkFlow.outBytes/1024/1024;
            __strong typeof(weakSelf) strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf->_hoverButton refreshButtonAtIndex:2 withBlock:^(UIButton *button) {
                    [button setTitle:[NSString stringWithFormat:@"%.2fMB", download] forState:UIControlStateNormal];
                }];
                [strongSelf->_hoverButton refreshButtonAtIndex:3 withBlock:^(UIButton *button) {
                    [button setTitle:[NSString stringWithFormat:@"%.2fMB", upload] forState:UIControlStateNormal];
                }];
            });
        }];
    }
}

- (void)stopMonitor {
    [self.fpsMonitor stop];
    [self.ramMonitor stop];
    [self.cpuMonitor stop];
    [self.netMonitor stop];
}

- (HACFps *)fpsMonitor {
    if (!_fpsMonitor) {
        _fpsMonitor = [[HACFps alloc] init];
    }
    return _fpsMonitor;
}

- (HACRam *)ramMonitor {
    if (!_ramMonitor) {
        _ramMonitor = [[HACRam alloc] init];
    }
    return _ramMonitor;
}

- (HACpu *)cpuMonitor {
    if (!_cpuMonitor) {
        _cpuMonitor = [[HACpu alloc] init];
    }
    return _cpuMonitor;
}

- (HACNetwork *)netMonitor {
    if (!_netMonitor) {
        _netMonitor = [[HACNetwork alloc] init];
    }
    return _netMonitor;
}
@end
