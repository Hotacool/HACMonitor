//
//  HACpuLoad.h
//  Pods
//
//  Created by macbook on 17/1/12.
//
//

#import "HACObject.h"

@interface HACpuLoad : HACObject
@property (nonatomic, assign) double system;
@property (nonatomic, assign) double user;
@property (nonatomic, assign) double nice;
@property (nonatomic, assign) double systemWithoutNice;
@property (nonatomic, assign) double userWithoutNice;
@property (nonatomic, assign) double total;
@end
