//
//  DYYYLongPressPanel.xm
//  DYYY-Optimized
//
//  长按面板增强
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

#import "DYYYCompat.h"

%group DYYYLongPressGroup

%hook AWECommentLongPressPanel

- (void)show {
    %orig;
    DYYYLog(@"Long press panel shown");
}

%end

%end // DYYYLongPressGroup

%ctor {
    %init(DYYYLongPressGroup);
}
