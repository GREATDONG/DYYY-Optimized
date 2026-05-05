//
//  DYYYImagePickerDelegate.h
//  DYYY-Optimized
//

#import <UIKit/UIKit.h>

@interface DYYYImagePickerDelegate : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, copy) void (^onImageSelected)(UIImage *image);

+ (void)presentFromViewController:(UIViewController *)viewController completion:(void (^)(UIImage *image))completion;

@end
