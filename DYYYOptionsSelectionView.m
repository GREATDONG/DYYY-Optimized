//
//  DYYYOptionsSelectionView.m
//  DYYY-Optimized
//

#import "DYYYOptionsSelectionView.h"

@implementation DYYYOptionsSelectionView

+ (void)showWithTitle:(NSString *)title options:(NSArray<NSString *> *)options completion:(void (^)(NSInteger index))completion {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (NSInteger i = 0; i < options.count; i++) {
        NSString *option = options[i];
        [alert addAction:[UIAlertAction actionWithTitle:option style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (completion) completion(i);
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    [topVC presentViewController:alert animated:YES completion:nil];
}

@end
