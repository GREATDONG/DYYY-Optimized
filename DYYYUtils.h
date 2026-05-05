//
//  DYYYUtils.h
//  DYYY-Optimized
//

#import <UIKit/UIKit.h>

@interface DYYYUtils : NSObject

+ (BOOL)isDarkMode;
+ (UIWindow *)getActiveWindow;
+ (UIViewController *)topView;
+ (void)showToast:(NSString *)message;

@end
