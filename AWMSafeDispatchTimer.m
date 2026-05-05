//
//  AWMSafeDispatchTimer.m
//  DYYY-Optimized
//

#import "AWMSafeDispatchTimer.h"

@interface AWMSafeDispatchTimer ()
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, strong) id userInfo;
@property (nonatomic, assign) BOOL repeats;
@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, strong) dispatch_source_t timer;
@end

@implementation AWMSafeDispatchTimer

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                        target:(id)target
                                      selector:(SEL)selector
                                      userInfo:(id)userInfo
                                       repeats:(BOOL)repeats {
    AWMSafeDispatchTimer *timer = [[self alloc] init];
    timer.target = target;
    timer.selector = selector;
    timer.userInfo = userInfo;
    timer.repeats = repeats;
    timer.interval = interval;
    [timer schedule];
    return timer;
}

- (void)schedule {
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    dispatch_source_set_timer(self.timer, 
                              dispatch_time(DISPATCH_TIME_NOW, self.interval * NSEC_PER_SEC),
                              self.interval * NSEC_PER_SEC, 
                              0);
    
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.timer, ^{
        [weakSelf fire];
    });
    
    dispatch_resume(self.timer);
}

- (void)fire {
    id target = self.target;
    if (target && [target respondsToSelector:self.selector]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [target performSelector:self.selector withObject:self];
        #pragma clang diagnostic pop
    }
    
    if (!self.repeats) {
        [self invalidate];
    }
}

- (void)invalidate {
    if (self.timer) {
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
}

- (void)dealloc {
    [self invalidate];
}

@end
