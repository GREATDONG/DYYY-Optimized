//
//  DYYYOptionsSelectionView.h
//  DYYY-Optimized
//

#import <UIKit/UIKit.h>

@interface DYYYOptionsSelectionView : UIView

+ (void)showWithTitle:(NSString *)title options:(NSArray<NSString *> *)options completion:(void (^)(NSInteger index))completion;

@end
