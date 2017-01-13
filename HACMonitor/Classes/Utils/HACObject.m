//
//  HACObject.m
//  Pods
//
//  Created by macbook on 17/1/12.
//
//

#import "HACObject.h"
#import <objc/runtime.h>
#import "HACHelp.h"

@implementation HACObject

- (NSArray *) allPropertyNames{
    NSMutableArray *allNames = [[NSMutableArray alloc] init];
    unsigned int propertyCount = 0;
    objc_property_t *propertys = class_copyPropertyList([self class], &propertyCount);
    
    for (int i = 0; i < propertyCount; i ++) {
        objc_property_t property = propertys[i];
        const char * propertyName = property_getName(property);
        [allNames addObject:[NSString stringWithUTF8String:propertyName]];
    }
    free(propertys);
    return allNames;
}

- (NSString *)description {
    NSArray *propArr = [self allPropertyNames];
    if (HACObjectIsEmpty(propArr)) {
        return [super description];
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:propArr.count];
    [propArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (HACObjectIsEmpty(obj)) {
            [dic setObject:@"" forKey:@"unknow"];
        } else {
            [dic setObject:[self valueForKey:obj]?:@"" forKey:obj];
        }
    }];
    return [dic description];
}
@end
