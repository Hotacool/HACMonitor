//
//  HACFps.m
//  Pods
//
//  Created by macbook on 17/1/16.
//
//

#import "HACFps.h"
#import "HACHelp.h"
#import "HACWeakObject.h"

@implementation HACFps {
    CADisplayLink *displayLink;
    HACFpsMonitorBlock fpsBlock;
    
    NSTimeInterval lastTime;
    NSUInteger count;
}

- (void)dealloc {
    [self stop];
}

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (BOOL)isActive {
    return (displayLink!=nil);
}

- (BOOL)startFpsMonitorBlock:(HACFpsMonitorBlock) block {
    if (HACObjectIsNull(block)) {
        return NO;
    }
    fpsBlock = block;
    displayLink = [CADisplayLink displayLinkWithTarget:[HACWeakObject weakObjectWithTarget:self] selector:@selector(handleDisplayLink:)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    return YES;
}

- (void)stop {
    fpsBlock = nil;
    [displayLink invalidate];
    displayLink = nil;
}

#pragma mark - private
- (void)handleDisplayLink:(CADisplayLink *)dlk {
    if (lastTime == 0) {
        lastTime = displayLink.timestamp;
        return;
    }
    count++;
    NSTimeInterval delta = displayLink.timestamp - lastTime;
    if (delta < 1) return;
    lastTime = displayLink.timestamp;
    CGFloat fps = count / delta;
    count = 0;
    
    if (fpsBlock) {
        fpsBlock(fps);
    }
}

@end
