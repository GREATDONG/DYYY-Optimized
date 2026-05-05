//
//  DYYYCompat.h
//  DYYY-Optimized
//
//  兼容层：集中管理类名定义和安全查找
//  基于 COLLAB.md 经验：先验证，再使用
//

#ifndef DYYYCompat_h
#define DYYYCompat_h

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ============================================
// 调试日志宏
// ============================================
#ifdef DEBUG
    #define DYYYLog(fmt, ...) NSLog(@"[DYYY] " fmt, ##__VA_ARGS__)
#else
    #define DYYYLog(fmt, ...) 
#endif

#define DYYYLogError(fmt, ...) NSLog(@"[DYYY] ERROR: " fmt, ##__VA_ARGS__)
#define DYYYLogWarning(fmt, ...) NSLog(@"[DYYY] WARNING: " fmt, ##__VA_ARGS__)

// ============================================
// 安全类型转换宏
// ============================================
#define DYYY_IS_KIND_OF(obj, cls) [(obj) isKindOfClass:[cls class]]
#define DYYY_RESPONDS_TO(obj, sel) [(obj) respondsToSelector:@selector(sel)]

// ============================================
// 核心类名定义
// ============================================

// 视频相关
#define DYYY_CLS_AWEURLModel             @"AWEURLModel"
#define DYYY_CLS_AWEVideoModel           @"AWEVideoModel"
#define DYYY_CLS_PlayInteractionVC       @"AWEPlayInteractionViewController"
#define DYYY_CLS_PlayVideoVC             @"AWEAwemePlayVideoViewController"
#define DYYY_CLS_FeedRootVC              @"AWEFeedRootViewController"

// 评论相关
#define DYYY_CLS_CommentContainerVC      @"AWECommentContainerViewController"
#define DYYY_CLS_SWIFT_CommentCopy       @"_TtC33AWECommentLongPressPanelSwiftImpl32CommentLongPressPanelCopyElement"
#define DYYY_CLS_SWIFT_CommentSticker    @"_TtCV28AWECommentPanelListSwiftImpl6NEWAPI27CommentCellStickerComponent"

// 用户相关
#define DYYY_CLS_UserActionSheetView     @"AWEUserActionSheetView"
#define DYYY_CLS_AppDelegate             @"AppDelegate"

// IM 相关
#define DYYY_CLS_IMReadReceiptDataCenter @"AWEIMReadReceiptDataCenter"
#define DYYY_CLS_IMConversation          @"AWEIMConversation"
#define DYYY_CLS_ProfileNavVisitorItem   @"AWEProfileNavVisitorItemController"

// 直播相关
#define DYYY_CLS_SWIFT_LiveRankEntrance  @"_TtC18IESLiveRevenueImpl34IESLiveDynamicRankListEntranceView"
#define DYYY_CLS_SWIFT_LiveUserEnter     @"_TtC18IESLiveRevenueImpl32IESLiveSwiftDynamicUserEnterView"

// ============================================
// 安全类查找函数
// ============================================

/**
 * 安全获取类对象
 * @param name 类名
 * @return 类对象，不存在时返回 nil 并记录日志
 */
static inline Class DYYYGetClass(NSString *name) {
    if (!name || name.length == 0) {
        DYYYLogError(@"Empty class name");
        return nil;
    }
    Class cls = objc_getClass(name.UTF8String);
    if (!cls) {
        DYYYLogWarning(@"Class not found: %@", name);
    }
    return cls;
}

/**
 * 从候选类名中查找第一个存在的类
 * @param names 候选类名数组
 * @return 第一个存在的类，都不存在时返回 nil
 */
static inline Class DYYYGetClassFromCandidates(NSArray<NSString *> *names) {
    if (!names || names.count == 0) {
        DYYYLogError(@"Empty candidates array");
        return nil;
    }
    
    for (NSString *name in names) {
        Class cls = objc_getClass(name.UTF8String);
        if (cls) {
            if (![name isEqualToString:names.firstObject]) {
                DYYYLog(@"Class fallback: %@ -> %@", names.firstObject, name);
            }
            return cls;
        }
    }
    
    DYYYLogError(@"All candidates failed: %@", [names componentsJoinedByString:@", "]);
    return nil;
}

/**
 * 检查类是否存在（用于条件编译）
 */
static inline BOOL DYYYClassExists(NSString *name) {
    return name && objc_getClass(name.UTF8String) != nil;
}

// ============================================
// 版本检测
// ============================================

/**
 * 获取抖音版本号
 */
static inline NSString *DYYYGetAwemeVersion(void) {
    Class appDelegateClass = DYYYGetClass(DYYY_CLS_AppDelegate);
    if (!appDelegateClass) return nil;
    
    // 尝试从 Info.plist 获取
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return version;
}

#endif /* DYYYCompat_h */
