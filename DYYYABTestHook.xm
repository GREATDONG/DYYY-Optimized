//
//  DYYYABTestHook.xm
//  DYYY-Optimized
//
//  ABTest 功能开关
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <substrate.h>

#import "DYYYCompat.h"

%group DYYYABTestGroup

%hook AWEABTestManager

- (BOOL)boolValueForKey:(NSString *)key {
    // 强制启用某些实验功能
    if ([key isEqualToString:@"enable_download"]) {
        return YES;
    }
    return %orig;
}

%end

%end // DYYYABTestGroup

%ctor {
    %init(DYYYABTestGroup);
}
