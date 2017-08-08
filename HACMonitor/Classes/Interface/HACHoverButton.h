//
//  HACHoverButton.h
//  HACMonitor
//
//  Created by Hotacool on 2017/8/7.
//

#import <UIKit/UIKit.h>

@interface HACHoverButton : UIWindow
@property (nonatomic, strong) NSArray *itemArray;
@property (nonatomic, copy) void (^selectBlock)(NSString *title, UIButton *button);

- (void)show ;
- (void)dismiss;
- (void)refreshButtonAtIndex:(NSUInteger)index withBlock:(void (^)(UIButton*))block ;
@end
