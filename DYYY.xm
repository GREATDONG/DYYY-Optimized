//
//  DYYY.xm
//  DYYY-Optimized
//
//  主 Hook 文件 - 优化版
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

#import "DYYYManager.h"
#import "DYYYToast.h"
#import "DYYYUtils.h"
#import "DYYYCompat.h"

#pragma mark - 配置工具

static BOOL DYYYGetBool(NSString *key, BOOL defaultValue) {
    if (!key) return defaultValue;
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    return value ? [value boolValue] : defaultValue;
}

static NSString *DYYYGetString(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] stringForKey:key];
}

#pragma mark - 视频下载 Hook

%group DYYYDownloadGroup

%hook AWEURLModel

- (NSURL *)url {
    NSURL *orig = %orig;
    if (!orig) return nil;
    
    // 获取无水印 URL
    NSString *urlString = orig.absoluteString;
    if ([urlString containsString:@"watermark"] || [urlString containsString:@"wm"]) {
        // 移除水印参数
        urlString = [urlString stringByReplacingOccurrencesOfString:@"&watermark=1" withString:@""];
        urlString = [urlString stringByReplacingOccurrencesOfString:@"&wm=1" withString:@""];
        return [NSURL URLWithString:urlString];
    }
    return orig;
}

%end

%end // DYYYDownloadGroup

#pragma mark - 界面优化 Hook

%group DYYYUIGroup

%hook AWEFeedRootViewController

- (void)viewDidLoad {
    %orig;
    DYYYLog(@"FeedRootViewController loaded");
}

%end

%end // DYYYUIGroup

#pragma mark - 初始化

%ctor {
    DYYYLog(@"DYYY-Optimized initializing...");
    
    // 初始化各功能模块
    %init(DYYYDownloadGroup);
    %init(DYYYUIGroup);
    
    DYYYLog(@"DYYY-Optimized initialized");
}
