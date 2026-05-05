//
//  DYYYUtils.m
//  DYYY-Optimized
//

#import "DYYYUtils.h"
#import "DYYYToast.h"

@implementation DYYYUtils

+ (BOOL)isDarkMode {
    if (@available(iOS 13.0, *)) {
        return UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    }
    return NO;
}

+ (UIWindow *)getActiveWindow {
    UIApplication *app = [UIApplication sharedApplication];
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
            }
        }
    }
    return app.keyWindow;
}

+ (UIViewController *)topView {
    UIWindow *window = [self getActiveWindow];
    UIViewController *topVC = window.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

+ (void)showToast:(NSString *)message {
    [DYYYToast showToast:message];
}

@end
