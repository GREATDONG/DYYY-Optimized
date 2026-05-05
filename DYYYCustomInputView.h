//
//  DYYYCustomInputView.h
//  DYYY-Optimized
//

#import <UIKit/UIKit.h>

@interface DYYYCustomInputView : UIView

@property (nonatomic, copy) void (^onConfirm)(NSString *text);

+ (void)showWithTitle:(NSString *)title placeholder:(NSString *)placeholder completion:(void (^)(NSString *text))completion;

@end
