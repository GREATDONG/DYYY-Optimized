//
//  DYYYAboutDialogView.m
//  DYYY-Optimized
//

#import "DYYYAboutDialogView.h"

@implementation DYYYAboutDialogView

+ (void)show {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"关于 DYYY-Optimized" 
                                                                   message:@"抖音优化插件 v2.4\n\n基于 DYYY 改进\n修复 IM 功能/代码优化" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    [topVC presentViewController:alert animated:YES completion:nil];
}

@end
