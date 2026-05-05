//
//  DYYYIMEnhancement.xm
//  DYYY IM Enhancement Features
//
//  Features:
//  1. Chat swipe gestures (left=quote, right=recall)
//  2. Block read receipts
//  3. Block visitor records
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

#import "DYYYManager.h"
#import "DYYYToast.h"
#import "DYYYUtils.h"

// ============================================================
// MARK: - Feature 1: Chat Swipe Gestures
// ============================================================

static char kDYYYSwipeGestureKey;

static id DYYYGetMessageFromCell(id cell) {
    if (!cell) return nil;
    if ([cell respondsToSelector:@selector(currentContext)]) {
        id context = ((id (*)(id, SEL))objc_msgSend)(cell, @selector(currentContext));
        if (context && [context respondsToSelector:@selector(message)]) {
            return ((id (*)(id, SEL))objc_msgSend)(context, @selector(message));
        }
    }
    if ([cell respondsToSelector:@selector(context)]) {
        id context = ((id (*)(id, SEL))objc_msgSend)(cell, @selector(context));
        if (context && [context respondsToSelector:@selector(message)]) {
            return ((id (*)(id, SEL))objc_msgSend)(context, @selector(message));
        }
    }
    if ([cell respondsToSelector:@selector(message)]) {
        return ((id (*)(id, SEL))objc_msgSend)(cell, @selector(message));
    }
    return nil;
}

static NSString *DYYYGetMessageSenderID(id message) {
    if (!message) return nil;
    if ([message respondsToSelector:@selector(fromUserId)]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, @selector(fromUserId));
    }
    if ([message respondsToSelector:@selector(senderId)]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, @selector(senderId));
    }
    if ([message respondsToSelector:@selector(user)]) {
        id user = ((id (*)(id, SEL))objc_msgSend)(message, @selector(user));
        if (user && [user respondsToSelector:@selector(userId)]) {
            return ((NSString *(*)(id, SEL))objc_msgSend)(user, @selector(userId));
        }
    }
    return nil;
}

static NSString *DYYYGetCurrentUserID() {
    Class cls = objc_getClass("AWEAccountService");
    if (!cls) cls = objc_getClass("AWELoginService");
    if (!cls) return nil;
    SEL sharedSel = @selector(sharedInstance);
    if (!class_getClassMethod(cls, sharedSel)) sharedSel = @selector(shared);
    if (!class_getClassMethod(cls, sharedSel)) return nil;
    id service = ((id (*)(id, SEL))objc_msgSend)(cls, sharedSel);
    if (!service) return nil;
    if ([service respondsToSelector:@selector(userId)]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(service, @selector(userId));
    }
    if ([service respondsToSelector:@selector(currentUserId)]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(service, @selector(currentUserId));
    }
    return nil;
}

static NSString *DYYYGetMessageID(id message) {
    if (!message) return nil;
    if ([message respondsToSelector:@selector(msgId)]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, @selector(msgId));
    }
    if ([message respondsToSelector:@selector(messageId)]) {
        return ((NSString *(*)(id, SEL))objc_msgSend)(message, @selector(messageId));
    }
    return nil;
}

static id DYYYGetConversationFromCell(id cell) {
    if (!cell) return nil;
    UIResponder *responder = cell;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            UIViewController *vc = (UIViewController *)responder;
            if ([vc respondsToSelector:@selector(conversation)]) {
                return ((id (*)(id, SEL))objc_msgSend)(vc, @selector(conversation));
            }
            if ([vc respondsToSelector:@selector(viewModel)]) {
                id vm = ((id (*)(id, SEL))objc_msgSend)(vc, @selector(viewModel));
                if (vm && [vm respondsToSelector:@selector(conversation)]) {
                    return ((id (*)(id, SEL))objc_msgSend)(vm, @selector(conversation));
                }
            }
        }
        responder = [responder nextResponder];
    }
    return nil;
}

static void DYYYQuoteMessage(id cell, id message) {
    id conversation = DYYYGetConversationFromCell(cell);
    if (conversation) {
        SEL selectors[] = {
            @selector(replyToMessage:),
            @selector(quoteMessage:),
            @selector(setReplyMessage:),
            @selector(setQuoteMessage:),
        };
        for (int i = 0; i < sizeof(selectors)/sizeof(selectors[0]); i++) {
            if ([conversation respondsToSelector:selectors[i]]) {
                ((void (*)(id, SEL, id))objc_msgSend)(conversation, selectors[i], message);
                NSLog(@"[DYYY] Quote via %@", NSStringFromSelector(selectors[i]));
                return;
            }
        }
    }
    UIResponder *responder = cell;
    while (responder) {
        if ([responder respondsToSelector:@selector(replyToMessage:)]) {
            ((void (*)(id, SEL, id))objc_msgSend)(responder, @selector(replyToMessage:), message);
            NSLog(@"[DYYY] Quote via responder chain");
            return;
        }
        responder = [responder nextResponder];
    }
    NSLog(@"[DYYY] Quote: no handler found");
    [DYYYToast showSuccessToastWithMessage:@"引用功能暂不可用"];
}

static void DYYYRecallMessage(id cell, id message) {
    NSString *senderId = DYYYGetMessageSenderID(message);
    NSString *currentUserId = DYYYGetCurrentUserID();
    if (senderId && currentUserId && ![senderId isEqualToString:currentUserId]) {
        [DYYYToast showSuccessToastWithMessage:@"只能撤回自己的消息"];
        return;
    }
    id conversation = DYYYGetConversationFromCell(cell);
    if (conversation) {
        SEL selectors[] = {
            @selector(revokeMessage:),
            @selector(recallMessage:),
            @selector(deleteMessage:),
            @selector(withdrawMessage:),
        };
        for (int i = 0; i < sizeof(selectors)/sizeof(selectors[0]); i++) {
            if ([conversation respondsToSelector:selectors[i]]) {
                ((void (*)(id, SEL, id))objc_msgSend)(conversation, selectors[i], message);
                NSLog(@"[DYYY] Recall via %@", NSStringFromSelector(selectors[i]));
                return;
            }
        }
    }
    NSLog(@"[DYYY] Recall: no handler found");
    [DYYYToast showSuccessToastWithMessage:@"撤回功能暂不可用"];
}

%group DYYYIMSwipeActionsGroup

%hook AWEIMReusableCommonCell

- (void)didMoveToSuperview {
    %orig;
    if (!DYYYGetBool(@"DYYYEnableSwipeActions")) return;
    for (UIGestureRecognizer *g in self.gestureRecognizers) {
        NSString *tag = objc_getAssociatedObject(g, &kDYYYSwipeGestureKey);
        if (tag && [tag hasPrefix:@"DYYY"]) return;
    }
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self action:@selector(dyyy_handleSwipeLeft:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    objc_setAssociatedObject(leftSwipe, &kDYYYSwipeGestureKey, @"DYYYLeft", OBJC_ASSOCIATION_RETAIN);
    [self addGestureRecognizer:leftSwipe];

    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self action:@selector(dyyy_handleSwipeRight:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    objc_setAssociatedObject(rightSwipe, &kDYYYSwipeGestureKey, @"DYYYRight", OBJC_ASSOCIATION_RETAIN);
    [self addGestureRecognizer:rightSwipe];
}

%new
- (void)dyyy_handleSwipeLeft:(UISwipeGestureRecognizer *)gesture {
    if (!DYYYGetBool(@"DYYYEnableSwipeActions")) return;
    NSLog(@"[DYYY] Left swipe on cell");
    id message = DYYYGetMessageFromCell(self);
    if (!message) {
        NSLog(@"[DYYY] Left swipe: no message");
        return;
    }
    DYYYQuoteMessage(self, message);
}

%new
- (void)dyyy_handleSwipeRight:(UISwipeGestureRecognizer *)gesture {
    if (!DYYYGetBool(@"DYYYEnableSwipeActions")) return;
    NSLog(@"[DYYY] Right swipe on cell");
    id message = DYYYGetMessageFromCell(self);
    if (!message) {
        NSLog(@"[DYYY] Right swipe: no message");
        return;
    }
    DYYYRecallMessage(self, message);
}

%end

%end // DYYYIMSwipeActionsGroup

// ============================================================
// MARK: - Feature 2 & 3: Network Request Interception
// Combined into one group to avoid duplicate NSURLSession hooks
// ============================================================

%group DYYYNetworkInterceptGroup

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSURL *url = request.URL;
    if (url) {
        NSString *absoluteString = url.absoluteString;
        NSString *path = url.path;

        // Feature 2: Block read receipts
        if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
            if (([absoluteString containsString:@"read_receipt"] ||
                 [absoluteString containsString:@"readreceipt"] ||
                 [absoluteString containsString:@"mark_read"] ||
                 [absoluteString containsString:@"ack_read"]) &&
                ![absoluteString containsString:@"feed"]) {
                NSLog(@"[DYYY] Blocked read receipt: %@", absoluteString);
                if (completionHandler) {
                    NSURLResponse *response = [[NSHTTPURLResponse alloc]
                        initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:nil];
                    completionHandler(nil, response, nil);
                }
                return nil;
            }
        }

        // Feature 3: Block visitor records
        if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
            if ([path containsString:@"/visitor"] ||
                [path containsString:@"/profile_visit"] ||
                [path containsString:@"/visit_record"] ||
                [absoluteString containsString:@"visitor"] ||
                [absoluteString containsString:@"profile_visit"]) {
                NSString *method = request.HTTPMethod;
                if ([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"]) {
                    NSLog(@"[DYYY] Blocked visitor upload: %@", absoluteString);
                    if (completionHandler) {
                        NSURLResponse *response = [[NSHTTPURLResponse alloc]
                            initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:nil];
                        completionHandler(nil, response, nil);
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
// MARK: - Runtime Hooks for Feature 2 & 3
// ============================================================

static void DYYYSetupRuntimeHooks() {
    // Feature 2: Hook read receipt classes
    Class readReceiptClass = objc_getClass("AWEIMReadReceiptDataCenter");
    if (readReceiptClass) {
        NSLog(@"[DYYY] Hooking AWEIMReadReceiptDataCenter");

        SEL reportSel = @selector(reportReadReceipt:);
        if (class_getInstanceMethod(readReceiptClass, reportSel)) {
            MSHookMessageEx(readReceiptClass, reportSel,
                ^(id self, id arg1) {
                    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
                        NSLog(@"[DYYY] Blocked reportReadReceipt:");
                        return;
                    }
                    ((void (*)(id, SEL, id))objc_msgSend)(self, reportSel, arg1);
                });
        }

        SEL ackSel = @selector(ackRead:);
        if (class_getInstanceMethod(readReceiptClass, ackSel)) {
            MSHookMessageEx(readReceiptClass, ackSel,
                ^(id self, id arg1) {
                    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
                        NSLog(@"[DYYY] Blocked ackRead:");
                        return;
                    }
                    ((void (*)(id, SEL, id))objc_msgSend)(self, ackSel, arg1);
                });
        }

        SEL sendSel = @selector(sendReadReceipt:);
        if (class_getInstanceMethod(readReceiptClass, sendSel)) {
            MSHookMessageEx(readReceiptClass, sendSel,
                ^(id self, id arg1) {
                    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
                        NSLog(@"[DYYY] Blocked sendReadReceipt:");
                        return;
                    }
                    ((void (*)(id, SEL, id))objc_msgSend)(self, sendSel, arg1);
                });
        }
    } else {
        NSLog(@"[DYYY] AWEIMReadReceiptDataCenter not found");
    }

    Class convClass = objc_getClass("AWEIMConversation");
    if (convClass) {
        SEL markSel = @selector(markConversationRead);
        if (class_getInstanceMethod(convClass, markSel)) {
            MSHookMessageEx(convClass, markSel,
                ^(id self) {
                    if (DYYYGetBool(@"DYYYBlockReadReceipt")) {
                        NSLog(@"[DYYY] Blocked markConversationRead");
                        return;
                    }
                    ((void (*)(id, SEL))objc_msgSend)(self, markSel);
                });
        }
    }

    // Feature 3: Hook visitor classes
    Class visitorVCClass = objc_getClass("AWEProfileNavVisitorItemController");
    if (visitorVCClass) {
        NSLog(@"[DYYY] Hooking AWEProfileNavVisitorItemController");

        SEL reportSel = @selector(reportVisit);
        if (class_getInstanceMethod(visitorVCClass, reportSel)) {
            MSHookMessageEx(visitorVCClass, reportSel,
                ^(id self) {
                    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
                        NSLog(@"[DYYY] Blocked reportVisit");
                        return;
                    }
                    ((void (*)(id, SEL))objc_msgSend)(self, reportSel);
                });
        }

        SEL enterSel = @selector(didEnterVisitorsPage);
        if (class_getInstanceMethod(visitorVCClass, enterSel)) {
            MSHookMessageEx(visitorVCClass, enterSel,
                ^(id self) {
                    if (DYYYGetBool(@"DYYYBlockVisitorUpload")) {
                        NSLog(@"[DYYY] Blocked didEnterVisitorsPage");
                        return;
                    }
                    ((void (*)(id, SEL))objc_msgSend)(self, enterSel);
                });
        }
    } else {
        NSLog(@"[DYYY] AWEProfileNavVisitorItemController not found");
    }
}

// ============================================================
// MARK: - Constructor
// ============================================================

%ctor {
    NSLog(@"[DYYY] DYYYIMEnhancement loading...");

    %init(DYYYIMSwipeActionsGroup);
    NSLog(@"[DYYY] IM Swipe Actions initialized");

    %init(DYYYNetworkInterceptGroup);
    DYYYSetupRuntimeHooks();
    NSLog(@"[DYYY] IM Network Interception initialized");
}
