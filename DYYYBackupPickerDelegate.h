//
//  DYYYBackupPickerDelegate.h
//  DYYY-Optimized
//

#import <UIKit/UIKit.h>

@interface DYYYBackupPickerDelegate : NSObject <UIDocumentPickerDelegate>

@property (nonatomic, copy) void (^onBackupSelected)(NSURL *url);

+ (void)presentFromViewController:(UIViewController *)viewController completion:(void (^)(NSURL *url))completion;

@end
