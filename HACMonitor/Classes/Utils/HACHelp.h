//
//  HACHelp.h
//  Pods
//
//  Created by macbook on 17/1/12.
//
//

#ifndef HACHelp_h
#define HACHelp_h

#ifdef DEBUG
#define NSLog(s,...) NSLog( @"<%@:(%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent],__LINE__,[NSString stringWithFormat:(s),##__VA_ARGS__])
#else
#define NSLog(s,...)
#endif

#define HACObjectIsNull(_object) (_object == nil \
|| [_object isKindOfClass:[NSNull class]])

#define HACObjectIsEmpty(_object) (_object == nil \
|| [_object isKindOfClass:[NSNull class]] \
|| ([_object respondsToSelector:@selector(length)] && [(NSData *)_object length] == 0) \
|| ([_object respondsToSelector:@selector(count)] && [(NSArray *)_object count] == 0))

#define HACBackground(block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)

#define HACMain(block) dispatch_async(dispatch_get_main_queue(),block)

/** 单例模式：声明 */
#define HAC_SINGLETON_DEFINE(_class_name_)  \
+ (_class_name_ *)shared##_class_name_;          \

/** 单例模式：实现 */
#define HAC_SINGLETON_IMPLEMENT(_class_name) HAC_SINGLETON_BOILERPLATE(_class_name, shared##_class_name)

#define HAC_SINGLETON_BOILERPLATE(_object_name_, _shared_obj_name_) \
static _object_name_ *z##_shared_obj_name_ = nil;  \
+ (_object_name_ *)_shared_obj_name_ {             \
static dispatch_once_t onceToken;              \
dispatch_once(&onceToken, ^{                   \
z##_shared_obj_name_ = [[self alloc] init];\
});                                            \
return z##_shared_obj_name_;                   \
}

#define HACBackground(block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)

#define HACMain(block) dispatch_async(dispatch_get_main_queue(),block)

#endif /* HACHelp_h */
