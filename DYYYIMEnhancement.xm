//
//  DYYYIMEnhancement.xm
//  DYYY IM Enhancement Features
//
//  Features:
//  1. Chat swipe gestures (left=quote, right=recall)
//  2. Block read receipts
//  3. Block visitor records
//
//  AI-assisted analysis via SiliconFlow DeepSeek-V3
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

#import "DYYYManager.h"
#import "DYYYToast.h"
#import "DYYYUtils.h"

// ============================================================
// MARK: - Safe Runtime Utilities
// ============================================================

static char kDYYYSwipeGestureKey;

static Class DYYYGetClass(const char *name) {
    Class cls = objc_getClass(name);
    if (!cls) NSLog(@"[DYYY-IM] Class %s not found", name);
    return cls;
}

static BOOL DYYYHasMethod(Class cls, SEL sel) {
    if (!cls) return NO;
    return class_getInstanceMethod(cls, sel) != NULL;
}

// ============================================================
// MARK: - Feature 1: Chat Swipe Gestures
// ============================================================

// Get message from cell via currentContext (declared in AwemeHeaders.h)
static id DYYYGetMessageFromCell(id cell) {
    if (!cell) return nil;
    // AWEIMReusableCommonCell.currentContext -> AWEIMMessageComponentContext.message
    if ([cell respondsToSelector:@selector(currentContext)]) {
        id ctx = ((id (*)(id, SEL))objc_msgSend)(cell, @selector(currentContext));
        if (ctx && [ctx respondsToSelector:@selector(message)]) {
            return ((id (*)(id, SEL))objc_msgSend)(ctx, @selector(message));
        }
    }
    return nil;
}

// Get current user ID for permission check
static NSString *DYYYGetCurrentUserID() {
    Class cls = DYYYGetClass("AWEAccountService");
    if (!cls) cls = DYYYGetClass("AWELoginService");
    if (!cls) return nil;

    SEL sel = @selector(sharedInstance);
    if (!class_getClassMethod(cls, sel)) sel = @selector(shared);
    if (!class_getClassMethod(cls, sel)) return nil;

    id svc = ((id (*)(id, SEL))objc_msgSend)(cls, sel);
    if (!svc) return nil;

    if ([svc respondsToSelector:@selector(userId)])
        return ((NSString *(*)(id, SEL))objc_msgSend)(svc, @selector(userId));
    if ([svc respondsToSelector:@selector(currentUserId)])
        return ((NSString *(*)(id, SEL))objc_msgSend)(svc, @selector(currentUserId));
    return nil;
}

// Get message sender ID
static NSString *DYYYGetSenderID(id message) {
    if (!message) return nil;
    if ([message respondsToSelector:@selector(fromUserId)])
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, @selector(fromUserId));
    if ([message respondsToSelector:@selector(senderId)])
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, @selector(senderId));
    return nil;
}

// Find conversation view controller from responder chain
static id DYYYFindConversationVC(UIResponder *responder) {
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            // Try common conversation VC class names
            Class convVC = DYYYGetClass("AWEIMConversationViewController");
            if (convVC && [responder isKindOfClass:convVC]) return responder;

            // Also check for viewModel with conversation property
            if ([responder respondsToSelector:@selector(viewModel)]) {
                id vm = ((id (*)(id, SEL))objc_msgSend)(responder, @selector(viewModel));
                if (vm && [vm respondsToSelector:@selector(conversation)])
                    return vm;
            }
            // Direct conversation property
            if ([responder respondsToSelector:@selector(conversation)])
                return ((id (*)(id, SEL))objc_msgSend)(responder, @selector(conversation));
        }
        responder = [responder nextResponder];
    }
    return nil;
}

// Quote message - try multiple known selectors
static void DYYYQuoteMessage(id cell, id message) {
    id target = DYYYFindConversationVC(cell);
    if (!target) {
        NSLog(@"[DYYY-IM] Quote: no conversation target found");
        [DYYYToast showSuccessToastWithMessage:@"引用功能暂不可用"];
        return;
    }

    // Try various reply/quote method signatures
    struct { SEL sel; int argCount; } tryList[] = {
        {@selector(replyToMessage:conversation:), 2},
        {@selector(replyToMessage:), 1},
        {@selector(quoteMessage:), 1},
        {@selector(setReplyMessage:), 1},
        {@selector(setQuoteMessage:), 1},
    };

    for (int i = 0; i < sizeof(tryList)/sizeof(tryList[0]); i++) {
        if ([target respondsToSelector:tryList[i].sel]) {
            if (tryList[i].argCount == 2) {
                // Need conversation as second arg
                id conv = nil;
                if ([target respondsToSelector:@selector(conversation)])
                    conv = ((id (*)(id, SEL))objc_msgSend)(target, @selector(conversation));
                if (conv) {
                    ((void (*)(id, SEL, id, id))objc_msgSend)(target, tryList[i].sel, message, conv);
                    NSLog(@"[DYYY-IM] Quote via %@ (2-arg)", NSStringFromSelector(tryList[i].sel));
                    return;
                }
            } else {
                ((void (*)(id, SEL, id))objc_msgSend)(target, tryList[i].sel, message);
                NSLog(@"[DYYY-IM] Quote via %@", NSStringFromSelector(tryList[i].sel));
                return;
            }
        }
    }

    NSLog(@"[DYYY-IM] Quote: no matching method on target class %@", NSStringFromClass([target class]));
    [DYYYToast showSuccessToastWithMessage:@"引用功能暂不可用"];
}

// Recall message - only own messages, try multiple selectors
static void DYYYRecallMessage(id cell, id message) {
    NSString *senderID = DYYYGetSenderID(message);
    NSString *myID = DYYYGetCurrentUserID();
    if (senderID && myID && ![senderID isEqualToString:myID]) {
        [DYYYToast showSuccessToastWithMessage:@"只能撤回自己的消息"];
        return;
    }

    id target = DYYYFindConversationVC(cell);
    if (!target) {
        NSLog(@"[DYYY-IM] Recall: no conversation target found");
        [DYYYToast showSuccessToastWithMessage:@"撤回功能暂不可用"];
        return;
    }

    // Try various revoke/recall method signatures
    struct { SEL sel; int argCount; } tryList[] = {
        {@selector(revokeMessage:completion:), 2},
        {@selector(revokeMessage:), 1},
        {@selector(recallMessage:), 1},
        {@selector(withdrawMessage:completion:), 2},
        {@selector(withdrawMessage:), 1},
        {@selector(deleteMessage:), 1},
    };

    for (int i = 0; i < sizeof(tryList)/sizeof(tryList[0]); i++) {
        if ([target respondsToSelector:tryList[i].sel]) {
            if (tryList[i].argCount == 2) {
                ((void (*)(id, SEL, id, id))objc_msgSend)(target, tryList[i].sel, message, ^(BOOL ok){});
                NSLog(@"[DYYY-IM] Recall via %@ (2-arg)", NSStringFromSelector(tryList[i].sel));
                return;
            } else {
                ((void (*)(id, SEL, id))objc_msgSend)(target, tryList[i].sel, message);
                NSLog(@"[DYYY-IM] Recall via %@", NSStringFromSelector(tryList[i].sel));
                return;
            }
        }
    }

    NSLog(@"[DYYY-IM] Recall: no matching method on target class %@", NSStringFromClass([target class]));
    [DYYYToast showSuccessToastWithMessage:@"撤回功能暂不可用"];
}

// ============================================================
// MARK: - Logos Hook: Feature 1
// ============================================================

%group DYYYIMSwipeActionsGroup

%hook AWEIMReusableCommonCell

- (void)didMoveToSuperview {
    %orig;

    if (!DYYYGetBool(@"DYYYEnableSwipeActions")) return;

    // Prevent duplicate gestures
    for (UIGestureRecognizer *g in self.gestureRecognizers) {
        NSString *tag = objc_getAssociatedObject(g, &kDYYYSwipeGestureKey);
        if (tag && [tag hasPrefix:@"DYYY"]) return;
    }

    // Left swipe -> Quote
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self action:@selector(dyyy_imSwipeLeft:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    leftSwipe.cancelsTouchesInView = NO;
    objc_setAssociatedObject(leftSwipe, &kDYYYSwipeGestureKey, @"DYYYLeft", OBJC_ASSOCIATION_RETAIN);
    [self addGestureRecognizer:leftSwipe];

    // Right swipe -> Recall
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self action:@selector(dyyy_imSwipeRight:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    rightSwipe.cancelsTouchesInView = NO;
    objc_setAssociatedObject(rightSwipe, &kDYYYSwipeGestureKey, @"DYYYRight", OBJC_ASSOCIATION_RETAIN);
    [self addGestureRecognizer:rightSwipe];
}

%new
- (void)dyyy_imSwipeLeft:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateRecognized) return;
    if (!DYYYGetBool(@"DYYYEnableSwipeActions")) return;
    NSLog(@"[DYYY-IM] Left swipe detected");
    id message = DYYYGetMessageFromCell(self);
    if (message) {
        DYYYQuoteMessage(self, message);
    } else {
        NSLog(@"[DYYY-IM] Left swipe: no message in cell");
    }
}

%new
- (void)dyyy_imSwipeRight:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateRecognized) return;
    if (!DYYYGetBool(@"DYYYEnableSwipeActions")) return;
    NSLog(@"[DYYY-IM] Right swipe detected");
    id message = DYYYGetMessageFromCell(self);
    if (message) {
        DYYYRecallMessage(self, message);
    } else {
        NSLog(@"[DYYY-IM] Right swipe: no message in cell");
    }
}

%end

%end // DYYYIMSwipeActionsGroup

// ============================================================
// MARK: - Logos Hook: Feature 2 & 3 (Network Layer)
// ============================================================

%group DYYYNetworkInterceptGroup

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (request.URL) {
        NSString *url = request.URL.absoluteString;

        // Feature 2: Block read receipt uploads
        if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
            if ([url containsString:@"im/read_receipt"] ||
                [url containsString:@"/im/v1/message/read"] ||
                [url containsString:@"/im/v1/message/ack"] ||
                [url containsString:@"readreceipt"] ||
                [url containsString:@"mark_read"]) {
                NSLog(@"[DYYY-IM] Blocked read receipt: %@", url);
                if (completionHandler) {
                    NSURLResponse *resp = [[NSHTTPURLResponse alloc]
                        initWithURL:request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:nil];
                    completionHandler(nil, resp, nil);
                }
                return nil;
            }
        }

        // Feature 3: Block visitor record uploads
        if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
            NSString *method = request.HTTPMethod;
            if ([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"]) {
                if ([url containsString:@"/visitor/record"] ||
                    [url containsString:@"/profile/visitor"] ||
                    [url containsString:@"/user/visitor"] ||
                    [url containsString:@"visitor"]) {
                    NSLog(@"[DYYY-IM] Blocked visitor upload: %@", url);
                    if (completionHandler) {
                        NSURLResponse *resp = [[NSHTTPURLResponse alloc]
                            initWithURL:request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:nil];
                        completionHandler(nil, resp, nil);
                    }
                    return nil;
                }
            }
        }
    }
    return %orig;
}

%end

%end // DYYYNetworkInterceptGroup

// ============================================================
// MARK: - Runtime Hooks: Feature 2 (Read Receipt)
// ============================================================

static IMP DYYYOrig_reportReadReceipt = NULL;
static IMP DYYYOrig_ackRead = NULL;
static IMP DYYYOrig_sendReadReceipt = NULL;
static IMP DYYYOrig_markConversationRead = NULL;

static void DYYYReplaced_reportReadReceipt(id self, SEL _cmd, id arg1) {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY-IM] Blocked reportReadReceipt:");
        return;
    }
    if (DYYYOrig_reportReadReceipt)
        ((void (*)(id, SEL, id))DYYYOrig_reportReadReceipt)(self, _cmd, arg1);
}

static void DYYYReplaced_ackRead(id self, SEL _cmd, id arg1) {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY-IM] Blocked ackRead:");
        return;
    }
    if (DYYYOrig_ackRead)
        ((void (*)(id, SEL, id))DYYYOrig_ackRead)(self, _cmd, arg1);
}

static void DYYYReplaced_sendReadReceipt(id self, SEL _cmd, id arg1) {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY-IM] Blocked sendReadReceipt:");
        return;
    }
    if (DYYYOrig_sendReadReceipt)
        ((void (*)(id, SEL, id))DYYYOrig_sendReadReceipt)(self, _cmd, arg1);
}

static void DYYYReplaced_markConversationRead(id self, SEL _cmd) {
    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
        NSLog(@"[DYYY-IM] Blocked markConversationRead");
        return;
    }
    if (DYYYOrig_markConversationRead)
        ((void (*)(id, SEL))DYYYOrig_markConversationRead)(self, _cmd);
}

// ============================================================
// MARK: - Runtime Hooks: Feature 3 (Visitor Records)
// ============================================================

static IMP DYYYOrig_reportVisit = NULL;
static IMP DYYYOrig_didEnterVisitorsPage = NULL;

static void DYYYReplaced_reportVisit(id self, SEL _cmd) {
    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
        NSLog(@"[DYYY-IM] Blocked reportVisit");
        return;
    }
    if (DYYYOrig_reportVisit)
        ((void (*)(id, SEL))DYYYOrig_reportVisit)(self, _cmd);
}

static void DYYYReplaced_didEnterVisitorsPage(id self, SEL _cmd) {
    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
        NSLog(@"[DYYY-IM] Blocked didEnterVisitorsPage");
        return;
    }
    if (DYYYOrig_didEnterVisitorsPage)
        ((void (*)(id, SEL))DYYYOrig_didEnterVisitorsPage)(self, _cmd);
}

// ============================================================
// MARK: - Setup All Runtime Hooks
// ============================================================

static void DYYYSetupRuntimeHooks() {
    // --- Feature 2: Read Receipt ---
    // Try multiple possible class names for read receipt manager
    const char *readReceiptClasses[] = {
        "AWEIMReadReceiptManager",
        "AWEIMReadReceiptDataCenter",
        "AWEIMReadReceiptService",
        NULL
    };
    for (int i = 0; readReceiptClasses[i]; i++) {
        Class cls = DYYYGetClass(readReceiptClasses[i]);
        if (!cls) continue;

        NSLog(@"[DYYY-IM] Found read receipt class: %s", readReceiptClasses[i]);

        Method m;
        m = class_getInstanceMethod(cls, @selector(reportReadReceipt:));
        if (m) { DYYYOrig_reportReadReceipt = method_setImplementation(m, (IMP)DYYYReplaced_reportReadReceipt); }

        m = class_getInstanceMethod(cls, @selector(ackRead:));
        if (m) { DYYYOrig_ackRead = method_setImplementation(m, (IMP)DYYYReplaced_ackRead); }

        m = class_getInstanceMethod(cls, @selector(sendReadReceipt:));
        if (m) { DYYYOrig_sendReadReceipt = method_setImplementation(m, (IMP)DYYYReplaced_sendReadReceipt); }

        // If we found and hooked at least one method, done
        if (DYYYOrig_reportReadReceipt || DYYYOrig_ackRead || DYYYOrig_sendReadReceipt) break;
    }

    // Also hook AWEIMConversation.markConversationRead
    Class convClass = DYYYGetClass("AWEIMConversation");
    if (convClass) {
        Method m = class_getInstanceMethod(convClass, @selector(markConversationRead));
        if (m) {
            DYYYOrig_markConversationRead = method_setImplementation(m, (IMP)DYYYReplaced_markConversationRead);
            NSLog(@"[DYYY-IM] Hooked AWEIMConversation.markConversationRead");
        }
    }

    // --- Feature 3: Visitor Records ---
    // Try multiple possible class names for visitor manager
    const char *visitorClasses[] = {
        "AWEUserProfileVisitorManager",
        "AWEProfileNavVisitorItemController",
        "AWEProfileVisitorManager",
        NULL
    };
    for (int i = 0; visitorClasses[i]; i++) {
        Class cls = DYYYGetClass(visitorClasses[i]);
        if (!cls) continue;

        NSLog(@"[DYYY-IM] Found visitor class: %s", visitorClasses[i]);

        Method m;
        m = class_getInstanceMethod(cls, @selector(reportVisit));
        if (m) { DYYYOrig_reportVisit = method_setImplementation(m, (IMP)DYYYReplaced_reportVisit); }

        m = class_getInstanceMethod(cls, @selector(didEnterVisitorsPage));
        if (m) { DYYYOrig_didEnterVisitorsPage = method_setImplementation(m, (IMP)DYYYReplaced_didEnterVisitorsPage); }

        if (DYYYOrig_reportVisit || DYYYOrig_didEnterVisitorsPage) break;
    }
}

// ============================================================
// MARK: - Constructor
// ============================================================

%ctor {
    NSLog(@"[DYYY-IM] DYYYIMEnhancement loading...");

    // Feature 1: Swipe gestures on chat cells
    %init(DYYYIMSwipeActionsGroup);
    NSLog(@"[DYYY-IM] Swipe Actions initialized");

    // Feature 2 & 3: Network layer interception
    %init(DYYYNetworkInterceptGroup);
    NSLog(@"[DYYY-IM] Network Interception initialized");

    // Feature 2 & 3: Runtime method hooks (class-level)
    DYYYSetupRuntimeHooks();
    NSLog(@"[DYYY-IM] Runtime Hooks initialized");
}
