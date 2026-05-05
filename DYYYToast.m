//
//  DYYYToast.m
//  DYYY-Optimized
//

#import "DYYYToast.h"

@implementation DYYYToast

+ (void)showToast:(NSString *)message {
    if (!message || message.length == 0) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        UILabel *label = [[UILabel alloc] init];
        label.text = message;
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:14];
        label.layer.cornerRadius = 8;
        label.layer.masksToBounds = YES;
        
        CGSize size = [message boundingRectWithSize:CGSizeMake(250, MAXFLOAT)
                                            options:NSStringDrawingUsesLineFragmentOrigin
                                         attributes:@{NSFontAttributeName: label.font}
                                            context:nil].size;
        label.frame = CGRectMake(0, 0, size.width + 30, size.height + 20);
        label.center = window.center;
        
        [window addSubview:label];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                label.alpha = 0;
            } completion:^(BOOL finished) {
                [label removeFromSuperview];
            }];
        });
    });
}

+ (void)showSuccessToast:(NSString *)message {
    [self showToast:message ?: @"操作成功"];
}

+ (void)showErrorToast:(NSString *)message {
    [self showToast:message ?: @"操作失败"];
}

@end
