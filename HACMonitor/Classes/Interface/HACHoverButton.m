//
//  HACHoverButton.m
//  HACMonitor
//
//  Created by Hotacool on 2017/8/7.
//

#import "HACHoverButton.h"
#import "UIImage+WM.h"          //图片扩展

#define kWMThisWidth CGRectGetWidth(self.frame)
#define kWMThisHeight CGRectGetHeight(self.frame)
#define kWMWindowWidth CGRectGetWidth(self.window.frame)
#define kWMWindowHeight CGRectGetHeight(self.window.frame)
#define HACHoverButtonCount (ceilf((float)self.itemArray.count/2))

static const CGFloat HACHoverButtonWidth = 50.0f;
static const NSUInteger HACHoverButtonTag = 0x999;
@interface HACHoverButton ()
@property (nonatomic, assign) UIWindow *window;
@property (nonatomic, strong) UIPanGestureRecognizer *pan;//移动
@property (nonatomic, strong) UITapGestureRecognizer *tap;//点击
@property (nonatomic, strong) UIButton *hoverButton;    //点击的小球
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, assign) BOOL  isShowTab;
@end

@implementation HACHoverButton

- (instancetype)init {
    if (self = [super init]) {
        self.window = [UIApplication sharedApplication].windows[0];
        
        CGFloat sWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat sHeight = [UIScreen mainScreen].bounds.size.height;
        self.frame = CGRectMake(sWidth - HACHoverButtonWidth/2, sHeight / 5, HACHoverButtonWidth, HACHoverButtonWidth);
        
        self.backgroundColor = [UIColor clearColor];
        self.windowLevel = UIWindowLevelAlert + 1;  //如果想在 alert 之上，则改成 + 2
        
        [self setUp];
    }
    return self;
}

- (void)setUp {
    [self addSubview:self.contentView];
    self.hoverButton.frame = (CGRect){0, 0, HACHoverButtonWidth, HACHoverButtonWidth};
    [self.hoverButton addTarget:self action:@selector(doTap:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.hoverButton];
    
    _pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(doPan:)];
    _pan.delaysTouchesBegan = NO;
    [self addGestureRecognizer:_pan];
    _tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doTap:)];
    [self addGestureRecognizer:_tap];
    
    self.layer.cornerRadius = HACHoverButtonWidth / 2;
    self.layer.borderWidth = (1/[UIScreen mainScreen].scale);
    self.layer.borderColor = [UIColor whiteColor].CGColor;
}

- (void)setItemArray:(NSArray *)itemArray {
    _itemArray = [itemArray copy];
    // create buttons
    for (UIView *item in self.contentView.subviews) {
        [item removeFromSuperview];
    }
    NSArray *colorArray = @[[UIColor redColor],
                            [UIColor greenColor],
                            [UIColor blueColor],
                            [UIColor cyanColor],
                            [UIColor yellowColor],
                            [UIColor magentaColor],
                            [UIColor orangeColor],
                            [UIColor purpleColor],
                            [UIColor brownColor],
                            [UIColor whiteColor],
                            ];
    
    for (int i=0; i<self.itemArray.count; i++) {
        NSString *title = self.itemArray[i];
        
        UIImage *nImage = [UIImage wm_imageWithColor:colorArray[i] withFrame:CGRectMake(0, 0, 18, 18)];
        nImage = [nImage wm_roundCorner];
        
        UIButton *button = [self customButton:i image:nImage title:title];
        [self.contentView addSubview:button];
    }
    self.contentView.frame = (CGRect){HACHoverButtonWidth ,0, HACHoverButtonCount * (HACHoverButtonWidth + 5),HACHoverButtonWidth};
}

- (void)show {
    [self makeKeyAndVisible];
}

- (void)dismiss {
    [self setHidden:YES];
}

- (void)refreshButtonAtIndex:(NSUInteger)index withBlock:(void (^)(UIButton*))block {
    if (index < self.itemArray.count) {
        UIButton *button = [self.contentView viewWithTag:HACHoverButtonTag+index];
        block(button);
    }
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.alpha  = 0;
    }
    return _contentView;
}

- (UIButton *)hoverButton {
    if (!_hoverButton) {
        _hoverButton =  [UIButton buttonWithType:UIButtonTypeCustom];
        _hoverButton.backgroundColor = [UIColor blueColor];
        _hoverButton.layer.shadowColor = [UIColor blackColor].CGColor;//shadowColor阴影颜色
        _hoverButton.layer.shadowOffset = CGSizeMake(0,0);//shadowOffset阴影偏移，默认(0, -3),这个跟shadowRadius配合使用
        _hoverButton.layer.shadowOpacity = 1;//阴影透明度，默认0
        _hoverButton.layer.shadowRadius = 3;//阴影半径，默认3
        _hoverButton.layer.masksToBounds = YES;
        _hoverButton.layer.cornerRadius = HACHoverButtonWidth / 2;
    }
    return _hoverButton;
}

//改变位置
- (void)doPan:(UIPanGestureRecognizer*)p {
    CGPoint panPoint = [p locationInView:self.window];
    
    if(p.state == UIGestureRecognizerStateBegan)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(changeStatus) object:nil];
    }
    if(p.state == UIGestureRecognizerStateChanged)
    {
        self.center = CGPointMake(panPoint.x, panPoint.y);
    }
    else if(p.state == UIGestureRecognizerStateEnded)
    {
//        [self stopAnimation];
        [self performSelector:@selector(changeStatus) withObject:nil afterDelay:3.0];
        
        if(panPoint.x <= kWMWindowWidth/2)
        {
            if(panPoint.y <= 40+kWMThisHeight/2 && panPoint.x >= 20+kWMThisWidth/2)
            {
                [UIView animateWithDuration:0.3 animations:^{
                    self.center = CGPointMake(panPoint.x, kWMThisHeight/2);
                }];
            }
            else if(panPoint.y >= kWMWindowHeight-kWMThisHeight/2-40 && panPoint.x >= 20+kWMThisWidth/2)
            {
                [UIView animateWithDuration:0.3 animations:^{
                    self.center = CGPointMake(panPoint.x, kWMWindowHeight-kWMThisHeight/2);
                }];
            }
            else if (panPoint.x < kWMThisWidth/2+20 && panPoint.y > kWMWindowHeight-kWMThisHeight/2)
            {
                [UIView animateWithDuration:0.3 animations:^{
                    self.center = CGPointMake(kWMThisWidth/2, kWMWindowHeight-kWMThisHeight/2);
                }];
            }
            else
            {
                CGFloat pointy = panPoint.y < kWMThisHeight/2 ? kWMThisHeight/2 :panPoint.y;
                [UIView animateWithDuration:0.3 animations:^{
                    self.center = CGPointMake(kWMThisWidth/2, pointy);
                }];
            }
        }
        else if(panPoint.x > kWMWindowWidth/2)
        {
            if(panPoint.y <= 40+kWMThisHeight/2 && panPoint.x < kWMWindowWidth-kWMThisWidth/2-20 )
            {
                [UIView animateWithDuration:0.3 animations:^{
                    self.center = CGPointMake(panPoint.x, kWMThisHeight/2);
                }];
            }
            else if(panPoint.y >= kWMWindowHeight-40-kWMThisHeight/2 && panPoint.x < kWMWindowWidth-kWMThisWidth/2-20)
            {
                [UIView animateWithDuration:0.3 animations:^{
                    self.center = CGPointMake(panPoint.x, kWMWindowHeight-kWMThisHeight/2);
                }];
            }
            else if (panPoint.x > kWMWindowWidth-kWMThisWidth/2-20 && panPoint.y < kWMThisHeight/2)
            {
                [UIView animateWithDuration:0.3 animations:^{
                    self.center = CGPointMake(kWMWindowWidth-kWMThisWidth/2, kWMThisHeight/2);
                }];
            }
            else
            {
                CGFloat pointy = panPoint.y > kWMWindowHeight-kWMThisHeight/2 ? kWMWindowHeight-kWMThisHeight/2 :panPoint.y;
                [UIView animateWithDuration:0.3 animations:^{
                    self.center = CGPointMake(kWMWindowWidth-kWMThisWidth/2, pointy);
                }];
            }
        }
    }
}

//点击事件
- (void)doTap:(UITapGestureRecognizer*)p {
    //拉出悬浮窗
    if (self.center.x == 0) {
        self.center = CGPointMake(kWMThisWidth/2, self.center.y);
    }else if (self.center.x == kWMWindowWidth) {
        self.center = CGPointMake(kWMWindowWidth - kWMThisWidth/2, self.center.y);
    }else if (self.center.y == 0) {
        self.center = CGPointMake(self.center.x, kWMThisHeight/2);
    }else if (self.center.y == kWMWindowHeight) {
        self.center = CGPointMake(self.center.x, kWMWindowHeight - kWMThisHeight/2);
    }
    
    CGFloat iWidth= (HACHoverButtonWidth + 5.0f);//每一个item 的宽度
    CGFloat thisX = CGRectGetMinX(self.frame);      //self.x
    CGFloat thisY = CGRectGetMinY(self.frame);      //self.y
    
    
    //展示按钮列表
    if (!self.isShowTab) {
        self.isShowTab = TRUE;
        
        //为了主按钮点击动画
        self.layer.masksToBounds = YES;
        
        [UIView animateWithDuration:0.1 animations:^{
            self.contentView.alpha  = 1;
            
            CGFloat sWidth = (kWMThisWidth + HACHoverButtonCount * iWidth);
            CGFloat sHeight = HACHoverButtonWidth * 2;
            
            //左边
            if (thisX <= kWMWindowWidth/2) {
                self.frame = CGRectMake(thisX, thisY, sWidth, sHeight);
                self.contentView.frame = (CGRect){iWidth, 0, sWidth - iWidth, sHeight};
            }else{
                CGFloat sLeft = thisX  - HACHoverButtonCount * iWidth;
                self.frame = CGRectMake(sLeft, thisY,  sWidth, sHeight);
                _hoverButton.frame = CGRectMake((HACHoverButtonCount * iWidth), 0, HACHoverButtonWidth, HACHoverButtonWidth);
                self.contentView.frame = (CGRect){10.0f, 0 , sWidth - HACHoverButtonWidth, sHeight};
            }
            self.backgroundColor = [UIColor colorWithRed:0x33/255.0f green:0x33/255.0f blue:0x33/255.0f alpha:0.5];
        }];
        
        //移除pan手势
        if (_pan) {
            [self removeGestureRecognizer:_pan];
        }
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(changeStatus) object:nil];
    }else{
        self.isShowTab = FALSE;
        
        //为了主按钮点击动画
        self.layer.masksToBounds = NO;
        
        //添加pan手势
        if (_pan) {
            [self addGestureRecognizer:_pan];
        }
        
        [UIView animateWithDuration:0.1 animations:^{
            
            self.contentView.alpha  = 0;
            
            if (thisX + CGRectGetMinX(_hoverButton.frame) <= kWMWindowWidth/2) {
                self.frame = CGRectMake(thisX, thisY, HACHoverButtonWidth ,HACHoverButtonWidth);
            }else{
                _hoverButton.frame = CGRectMake(0, 0, HACHoverButtonWidth, HACHoverButtonWidth);
                self.frame = CGRectMake(thisX + HACHoverButtonCount * iWidth, thisY, HACHoverButtonWidth ,HACHoverButtonWidth);
            }
            self.backgroundColor = [UIColor clearColor];
        }];
        [self performSelector:@selector(changeStatus) withObject:nil afterDelay:3.0];
    }
}

- (void)changeStatus {
    [UIView animateWithDuration:0.5 animations:^{
        CGFloat x = self.center.x < 20+kWMThisWidth/2 ? 0 :  self.center.x > kWMWindowWidth - 20 -kWMThisWidth/2 ? kWMWindowWidth : self.center.x;
        CGFloat y = self.center.y < 40 + kWMThisHeight/2 ? 0 : self.center.y > kWMWindowHeight - 40 - kWMThisHeight/2 ? kWMWindowHeight : self.center.y;
        
        //禁止停留在4个角
        if((x == 0 && y ==0) || (x == kWMWindowWidth && y == 0) || (x == 0 && y == kWMWindowHeight) || (x == kWMWindowWidth && y == kWMWindowHeight)){
            y = self.center.y;
        }
        self.center = CGPointMake(x, y);
    }];
}

- (UIButton *)customButton:(NSInteger)index image:(UIImage *)image title:(NSString *)title {
    CGFloat top = (index % 2 == 0) ? 0 : HACHoverButtonWidth;
    CGFloat left = (index / 2) * HACHoverButtonWidth;
    
    UIButton *bbb = [UIButton buttonWithType:UIButtonTypeCustom];
    bbb.tag = index + HACHoverButtonTag;
    [bbb setFrame: CGRectMake(left, top, HACHoverButtonWidth , HACHoverButtonWidth)];
    [bbb setBackgroundColor:[UIColor clearColor]];
    [bbb setTitle:title forState:UIControlStateNormal];
    bbb.titleLabel.font = [UIFont systemFontOfSize:12];
    bbb.titleLabel.adjustsFontSizeToFitWidth = YES;
    [bbb addTarget:self action:@selector(itemsClick:) forControlEvents:UIControlEventTouchUpInside];// 点击操作
    
    if (image) {
        [bbb setImage:image forState:UIControlStateNormal];
        [bbb wm_titleUnderIcon:5];
    }
    
    return bbb;
}

//点击事件
- (void)itemsClick:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger t = button.tag - HACHoverButtonTag;
    
    NSString *title = self.itemArray[t];
    if (self.isShowTab){
        [self doTap:nil];
    }
    
    if (self.selectBlock) {
        self.selectBlock(title, button);
    }
    
}
@end
