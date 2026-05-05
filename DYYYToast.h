//
//  DYYYToast.h
//  DYYY-Optimized
//

#import <UIKit/UIKit.h>

@interface DYYYToast : UIView

+ (void)showToast:(NSString *)message;
+ (void)showSuccessToast:(NSString *)message;
+ (void)showErrorToast:(NSString *)message;

@end
