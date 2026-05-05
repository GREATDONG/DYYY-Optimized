//
//  DYYYSettings.xm
//  DYYY-Optimized
//
//  设置界面 Hook
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

#import "DYYYUtils.h"
#import "DYYYToast.h"
#import "DYYYCompat.h"

#pragma mark - 设置按钮 Hook

%group DYYYSettingsGroup

%hook AWELeftSideBarTopIconHorizontalView

- (void)didMoveToSuperview {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *accessibilityLabel = self.accessibilityLabel;
        if (![accessibilityLabel isEqualToString:@"设置"]) {
            return;
        }
        
        UIView *targetSuperView = self.superview.superview.superview ?: self;
        UIButton *oldBtn = (UIButton *)[targetSuperView viewWithTag:232323];
        if (oldBtn) {
            [oldBtn removeFromSuperview];
        }
        
        UIButton *dyyyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        dyyyBtn.tag = 232323;
        dyyyBtn.accessibilityLabel = @"DYYYSettingsButton";
        [dyyyBtn setTitle:@"DYYY" forState:UIControlStateNormal];
        
        UIColor *titleColor = [DYYYUtils isDarkMode] ? [UIColor whiteColor] : [UIColor blackColor];
        [dyyyBtn setTitleColor:titleColor forState:UIControlStateNormal];
        dyyyBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        
        CGRect frame = self.frame;
        dyyyBtn.frame = CGRectMake(frame.origin.x + frame.size.width - 40 - 2, 8, 60, 32);
        dyyyBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        dyyyBtn.layer.cornerRadius = 8;
        dyyyBtn.clipsToBounds = YES;
        
        [dyyyBtn addTarget:self action:@selector(dyyyButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [targetSuperView addSubview:dyyyBtn];
    });
}

%new
- (void)dyyyButtonTapped {
    [DYYYToast showToast:@"DYYY 设置界面"];
    // 实际实现需要打开设置页面
}

%end

%end // DYYYSettingsGroup

%ctor {
    %init(DYYYSettingsGroup);
}
