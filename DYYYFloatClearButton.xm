//
//  DYYYFloatClearButton.xm
//  DYYY-Optimized
//
//  悬浮清理按钮
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

#import "DYYYCompat.h"

%group DYYYFloatButtonGroup

%hook UIWindow

- (void)layoutSubviews {
    %orig;
    // 悬浮按钮实现
}

%end

%end // DYYYFloatButtonGroup

%ctor {
    %init(DYYYFloatButtonGroup);
}
