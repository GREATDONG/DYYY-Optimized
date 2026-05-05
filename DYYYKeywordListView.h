//
//  DYYYKeywordListView.h
//  DYYY-Optimized
//

#import <UIKit/UIKit.h>

@interface DYYYKeywordListView : UIView

+ (void)showWithTitle:(NSString *)title keywords:(NSArray<NSString *> *)keywords completion:(void (^)(NSArray<NSString *> *))completion;

@end
