//
//  AWMSafeDispatchTimer.h
//  DYYY-Optimized
//

#import <Foundation/Foundation.h>

@interface AWMSafeDispatchTimer : NSObject

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                        target:(id)target
                                      selector:(SEL)selector
                                      userInfo:(id)userInfo
                                       repeats:(BOOL)repeats;

- (void)invalidate;

@end
