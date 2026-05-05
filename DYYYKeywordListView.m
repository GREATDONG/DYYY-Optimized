//
//  DYYYKeywordListView.m
//  DYYY-Optimized
//

#import "DYYYKeywordListView.h"

@implementation DYYYKeywordListView

+ (void)showWithTitle:(NSString *)title keywords:(NSArray<NSString *> *)keywords completion:(void (^)(NSArray<NSString *> *))completion {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"输入关键词，用逗号分隔";
        textField.text = [keywords componentsJoinedByString:@","];
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *text = alert.textFields.firstObject.text;
        NSArray *newKeywords = [text componentsSeparatedByString:@","];
        if (completion) completion(newKeywords);
    }]];
    
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    [topVC presentViewController:alert animated:YES completion:nil];
}

@end
