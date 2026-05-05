//
//  DYYYBackupPickerDelegate.m
//  DYYY-Optimized
//

#import "DYYYBackupPickerDelegate.h"

@implementation DYYYBackupPickerDelegate

+ (void)presentFromViewController:(UIViewController *)viewController completion:(void (^)(NSURL *url))completion {
    DYYYBackupPickerDelegate *delegate = [[self alloc] init];
    delegate.onBackupSelected = completion;
    
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.json"] inMode:UIDocumentPickerModeImport];
    picker.delegate = delegate;
    
    objc_setAssociatedObject(picker, @"delegate", delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [viewController presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count > 0 && self.onBackupSelected) {
        self.onBackupSelected(urls.firstObject);
    }
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    // 取消选择
}

@end
