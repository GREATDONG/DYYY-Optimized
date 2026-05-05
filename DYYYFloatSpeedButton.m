//
//  DYYYFloatSpeedButton.m
//  DYYY-Optimized
//

#import "DYYYFloatSpeedButton.h"

@implementation DYYYFloatSpeedButton

+ (instancetype)sharedInstance {
    static DYYYFloatSpeedButton *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.frame = CGRectMake(100, 100, 60, 60);
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        self.layer.cornerRadius = 30;
        [self setTitle:@"速度" forState:UIControlStateNormal];
    }
    return self;
}

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];
}

- (void)hide {
    [self removeFromSuperview];
}

@end
