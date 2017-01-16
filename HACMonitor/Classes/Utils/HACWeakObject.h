//
//  HACWeakObject.h
//  Pods
//
//  Created by macbook on 17/1/16.
//
//

#import "HACObject.h"

@interface HACWeakObject : HACObject
@property (nonatomic, weak, readonly) HACObject *target;

+ (instancetype)weakObjectWithTarget:(HACObject*)target ;
@end
