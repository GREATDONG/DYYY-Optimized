//
//  DYYYImagePickerDelegate.m
//  DYYY-Optimized
//

#import "DYYYImagePickerDelegate.h"

@interface DYYYImagePickerDelegate ()
@property (nonatomic, weak) UIViewController *presentingViewController;
@end

@implementation DYYYImagePickerDelegate

+ (void)presentFromViewController:(UIViewController *)viewController completion:(void (^)(UIImage *image))completion {
    DYYYImagePickerDelegate *delegate = [[self alloc] init];
    delegate.onImageSelected = completion;
    delegate.presentingViewController = viewController;
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = delegate;
    
    objc_setAssociatedObject(picker, @"delegate", delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [viewController presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (self.onImageSelected) {
        self.onImageSelected(image);
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
