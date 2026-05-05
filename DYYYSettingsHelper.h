//
//  DYYYSettingsHelper.h
//  DYYY-Optimized
//

#import <UIKit/UIKit.h>

@interface DYYYSettingsHelper : NSObject

+ (id)getUserDefaults:(NSString *)key;
+ (void)setUserDefaults:(id)value forKey:(NSString *)key;
+ (UIViewController *)findViewController:(UIView *)view;

@end
