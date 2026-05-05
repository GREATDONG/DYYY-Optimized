//
//  DYYYConfirmCloseView.h
//  DYYY-Optimized
//

#import <UIKit/UIKit.h>

@interface DYYYConfirmCloseView : UIView

+ (void)showWithCompletion:(void (^)(BOOL confirmed))completion;

@end
