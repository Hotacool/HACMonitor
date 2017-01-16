//
//  HACWeakObject.m
//  Pods
//
//  Created by macbook on 17/1/16.
//
//

#import "HACWeakObject.h"

@interface HACWeakObject ()
@property (nonatomic, weak, readwrite) HACObject *target;

@end

@implementation HACWeakObject

+ (instancetype)weakObjectWithTarget:(HACObject *)target {
    HACWeakObject *weakObject = [[HACWeakObject alloc] init];
    weakObject.target = target;
    return weakObject;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (self.target&&[self.target respondsToSelector:aSelector]) {
        return self.target;
    }
    return nil;
}
@end
