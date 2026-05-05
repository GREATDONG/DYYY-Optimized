//
//  DYYYIMEnhancement.xm
//  DYYY-Optimized
//
//  IM 聊天增强功能 - 修复版
//  修复问题：开关无效、%group 未正确启用
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

#import "DYYYManager.h"
#import "DYYYToast.h"
#import "DYYYUtils.h"
#import "DYYYCompat.h"

#pragma mark - 配置读取工具

/**
 * 安全读取布尔配置
 * 修复：确保配置键正确读取
 */
static BOOL DYYYGetBoolConfig(NSString *key, BOOL defaultValue) {
    if (!key || key.length == 0) {
        return defaultValue;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id value = [defaults objectForKey:key];
    if (value == nil) {
        return defaultValue;
    }
    return [value boolValue];
}

#pragma mark - 功能1: 滑动手势（引用/撤回）

// Associated Object Keys
static char kDYYYSwipeGestureKey;

/**
 * 从 Cell 获取消息对象 - 多策略降级
 */
static id DYYYGetMessageFromCell(id cell) {
    if (!cell) return nil;
    
    // 策略1: 通过 context 获取
    SEL contextSel = NSSelectorFromString(@"context");
    if ([cell respondsToSelector:contextSel]) {
        id context = ((id (*)(id, SEL))objc_msgSend)(cell, contextSel);
        if (context) {
            SEL messageSel = NSSelectorFromString(@"message");
            if ([context respondsToSelector:messageSel]) {
                return ((id (*)(id, SEL))objc_msgSend)(context, messageSel);
            }
            // 尝试 componentContext
            SEL compCtxSel = NSSelectorFromString(@"componentContext");
            if ([context respondsToSelector:compCtxSel]) {
                id compCtx = ((id (*)(id, SEL))objc_msgSend)(context, compCtxSel);
                if (compCtx && [compCtx respondsToSelector:messageSel]) {
                    return ((id (*)(id, SEL))objc_msgSend)(compCtx, messageSel);
                }
            }
        }
    }
    
    // 策略2: 直接获取 message
    SEL msgSel = NSSelectorFromString(@"message");
    if ([cell respondsToSelector:msgSel]) {
        return ((id (*)(id, SEL))objc_msgSend)(cell, msgSel);
    }
    
    // 策略3: 通过 model 获取
    SEL modelSel = NSSelectorFromString(@"model");
    if ([cell respondsToSelector:modelSel]) {
        id model = ((id (*)(id, SEL))objc_msgSend)(cell, modelSel);
        if (model && [model respondsToSelector:msgSel]) {
            return ((id (*)(id, SEL))objc_msgSend)(model, msgSel);
        }
    }
    
    return nil;
}

/**
 * 获取消息ID
 */
static NSString *DYYYGetMessageID(id message) {
    if (!message) return nil;
    
    SEL msgIdSel = NSSelectorFromString(@"msgId");
    if ([message respondsToSelector:msgIdSel]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, msgIdSel);
    }
    
    SEL idSel = NSSelectorFromString(@"Id");
    if ([message respondsToSelector:idSel]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, idSel);
    }
    
    return nil;
}

/**
 * 引用消息
 */
static void DYYYQuoteMessage(id cell, id message) {
    NSString *msgId = DYYYGetMessageID(message);
    if (!msgId) {
        [DYYYToast showSuccessToastWithMessage:@"无法获取消息ID"];
        return;
    }
    
    // 尝试多种引用方式
    BOOL success = NO;
    
    // 方式1: 通过 cell 的 quoteAction
    SEL quoteActionSel = NSSelectorFromString(@"quoteAction");
    if ([cell respondsToSelector:quoteActionSel]) {
        ((void (*)(id, SEL))objc_msgSend)(cell, quoteActionSel);
        success = YES;
    }
    
    // 方式2: 通过 delegate
    if (!success) {
        SEL delegateSel = NSSelectorFromString(@"delegate");
        if ([cell respondsToSelector:delegateSel]) {
            id delegate = ((id (*)(id, SEL))objc_msgSend)(cell, delegateSel);
            SEL quoteSel = NSSelectorFromString(@"didTapQuoteButton:");
            if ([delegate respondsToSelector:quoteSel]) {
                ((void (*)(id, SEL, id))objc_msgSend)(delegate, quoteSel, message);
                success = YES;
            }
        }
    }
    
    // 方式3: 发送通知
    if (!success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DYYYQuoteMessage" object:message];
        success = YES;
    }
    
    if (success) {
        [DYYYToast showSuccessToastWithMessage:@"已引用消息"];
    } else {
        [DYYYToast showSuccessToastWithMessage:@"引用功能暂不可用"];
    }
}

/**
 * 撤回消息
 */
static void DYYYRecallMessage(id cell, id message) {
    NSString *msgId = DYYYGetMessageID(message);
    if (!msgId) {
        [DYYYToast showSuccessToastWithMessage:@"无法获取消息ID"];
        return;
    }
    
    // 获取撤回服务
    Class recallServiceClass = objc_getClass("AWEIMRecallService");
    if (!recallServiceClass) {
        recallServiceClass = objc_getClass("AWEIMMessageService");
    }
    
    if (recallServiceClass) {
        SEL sharedSel = NSSelectorFromString(@"sharedInstance");
        if (class_getClassMethod(recallServiceClass, sharedSel)) {
            id recallSvc = ((id (*)(id, SEL))objc_msgSend)(recallServiceClass, sharedSel);
            SEL recallSel = NSSelectorFromString(@"recallMessage:completion:");
            if ([recallSvc respondsToSelector:recallSel]) {
                // 使用 block 回调
                void (^completion)(id) = ^(id result) {
                    [DYYYToast showSuccessToastWithMessage:@"已撤回消息"];
                };
                ((void (*)(id, SEL, id, id))objc_msgSend)(recallSvc, recallSel, message, completion);
                return;
            }
        }
    }
    
    [DYYYToast showSuccessToastWithMessage:@"撤回功能暂不可用"];
}

// 滑动手势回调
static void DYYYHandleSwipeGesture(UISwipeGestureRecognizer *gesture) {
    if (!DYYYGetBoolConfig(@"DYYYEnableSwipeActions", YES)) {
        return; // 功能开关关闭
    }
    
    if (gesture.state != UIGestureRecognizerStateEnded) return;
    
    UIView *cell = gesture.view;
    if (!cell) return;
    
    id message = DYYYGetMessageFromCell(cell);
    if (!message) {
        [DYYYToast showSuccessToastWithMessage:@"无法获取消息"];
        return;
    }
    
    if (gesture.direction == UISwipeGestureRecognizerDirectionLeft) {
        DYYYQuoteMessage(cell, message);
    } else if (gesture.direction == UISwipeGestureRecognizerDirectionRight) {
        DYYYRecallMessage(cell, message);
    }
}

#pragma mark - 功能2: 阻止已读回执

// 保存原始 IMP
static IMP origReportReadReceipt = NULL;
static IMP origAckRead = NULL;
static IMP origSendReadReceipt = NULL;
static IMP origMarkConversationRead = NULL;

/**
 * 替换后的 reportReadReceipt 实现
 */
static void DYYYReplacedReportReadReceipt(id self, SEL _cmd, id arg1) {
    if (!DYYYGetBoolConfig(@"DYYYBlockReadReceipt", NO)) {
        // 开关关闭，调用原始实现
        if (origReportReadReceipt) {
            ((void (*)(id, SEL, id))origReportReadReceipt)(self, _cmd, arg1);
        }
    }
    // 开关打开，不执行任何操作（阻止上报）
}

/**
 * 替换后的 ackRead 实现
 */
static void DYYYReplacedAckRead(id self, SEL _cmd, id arg1) {
    if (!DYYYGetBoolConfig(@"DYYYBlockReadReceipt", NO)) {
        if (origAckRead) {
            ((void (*)(id, SEL, id))origAckRead)(self, _cmd, arg1);
        }
    }
}

/**
 * 替换后的 sendReadReceipt 实现
 */
static void DYYYReplacedSendReadReceipt(id self, SEL _cmd, id arg1) {
    if (!DYYYGetBoolConfig(@"DYYYBlockReadReceipt", NO)) {
        if (origSendReadReceipt) {
            ((void (*)(id, SEL, id))origSendReadReceipt)(self, _cmd, arg1);
        }
    }
}

/**
 * 替换后的 markConversationRead 实现
 */
static void DYYYReplacedMarkConversationRead(id self, SEL _cmd) {
    if (!DYYYGetBoolConfig(@"DYYYBlockReadReceipt", NO)) {
        if (origMarkConversationRead) {
            ((void (*)(id, SEL))origMarkConversationRead)(self, _cmd);
        }
    }
}

/**
 * 设置已读回执拦截
 */
static void DYYYSetupReadReceiptHooks(void) {
    // Hook AWEIMReadReceiptDataCenter
    Class readReceiptClass = DYYYGetClass(DYYY_CLS_IMReadReceiptDataCenter);
    if (readReceiptClass) {
        SEL reportSel = NSSelectorFromString(@"reportReadReceipt:");
        SEL ackSel = NSSelectorFromString(@"ackRead:");
        SEL sendSel = NSSelectorFromString(@"sendReadReceipt:");
        
        Method reportMethod = class_getInstanceMethod(readReceiptClass, reportSel);
        Method ackMethod = class_getInstanceMethod(readReceiptClass, ackSel);
        Method sendMethod = class_getInstanceMethod(readReceiptClass, sendSel);
        
        if (reportMethod) {
            origReportReadReceipt = method_getImplementation(reportMethod);
            method_setImplementation(reportMethod, (IMP)DYYYReplacedReportReadReceipt);
        }
        if (ackMethod) {
            origAckRead = method_getImplementation(ackMethod);
            method_setImplementation(ackMethod, (IMP)DYYYReplacedAckRead);
        }
        if (sendMethod) {
            origSendReadReceipt = method_getImplementation(sendMethod);
            method_setImplementation(sendMethod, (IMP)DYYYReplacedSendReadReceipt);
        }
    }
    
    // Hook AWEIMConversation
    Class conversationClass = DYYYGetClass(DYYY_CLS_IMConversation);
    if (conversationClass) {
        SEL markReadSel = NSSelectorFromString(@"markConversationRead");
        Method markReadMethod = class_getInstanceMethod(conversationClass, markReadSel);
        if (markReadMethod) {
            origMarkConversationRead = method_getImplementation(markReadMethod);
            method_setImplementation(markReadMethod, (IMP)DYYYReplacedMarkConversationRead);
        }
    }
}

#pragma mark - 功能3: 阻止访客记录上传

/**
 * 替换后的访客上报实现
 */
static void DYYYReplacedReportVisit(id self, SEL _cmd) {
    if (!DYYYGetBoolConfig(@"DYYYBlockVisitorUpload", NO)) {
        // 获取原始 IMP 并调用
        IMP orig = class_getMethodImplementation([self class], _cmd);
        if (orig) {
            ((void (*)(id, SEL))orig)(self, _cmd);
        }
    }
    // 开关打开，不执行任何操作
}

/**
 * 设置访客记录拦截
 */
static void DYYYSetupVisitorHooks(void) {
    Class visitorClass = DYYYGetClass(DYYY_CLS_ProfileNavVisitorItem);
    if (visitorClass) {
        SEL reportSel = NSSelectorFromString(@"reportVisit");
        SEL enterSel = NSSelectorFromString(@"didEnterVisitorsPage");
        
        Method reportMethod = class_getInstanceMethod(visitorClass, reportSel);
        Method enterMethod = class_getInstanceMethod(visitorClass, enterSel);
        
        if (reportMethod) {
            method_setImplementation(reportMethod, (IMP)DYYYReplacedReportVisit);
        }
        if (enterMethod) {
            method_setImplementation(enterMethod, (IMP)DYYYReplacedReportVisit);
        }
    }
}

#pragma mark - Logos Hooks

// 滑动手势功能
%group DYYYIMSwipeActionsGroup

%hook AWEIMMessageCell

- (void)layoutSubviews {
    %orig;
    
    // 检查功能开关
    if (!DYYYGetBoolConfig(@"DYYYEnableSwipeActions", YES)) {
        return;
    }
    
    // 检查是否已添加手势
    if (objc_getAssociatedObject(self, &kDYYYSwipeGestureKey)) {
        return;
    }
    
    // 添加左滑手势（引用）
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dyyy_handleSwipe:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:leftSwipe];
    
    // 添加右滑手势（撤回）
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dyyy_handleSwipe:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:rightSwipe];
    
    // 标记已添加
    objc_setAssociatedObject(self, &kDYYYSwipeGestureKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (void)dyyy_handleSwipe:(UISwipeGestureRecognizer *)gesture {
    DYYYHandleSwipeGesture(gesture);
}

%end

%end // DYYYIMSwipeActionsGroup

#pragma mark - 初始化

%ctor {
    // 延迟初始化，确保抖音已加载
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        DYYYLog(@"IM Enhancement initializing...");
        
        // 启用滑动手势
        %init(DYYYIMSwipeActionsGroup);
        
        // 设置已读回执拦截
        DYYYSetupReadReceiptHooks();
        
        // 设置访客记录拦截
        DYYYSetupVisitorHooks();
        
        DYYYLog(@"IM Enhancement initialized");
    });
}
