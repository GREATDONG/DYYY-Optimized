//
//  CityManager.m
//  DYYY-Optimized
//

#import "CityManager.h"

@interface CityManager ()
@property (nonatomic, strong) NSString *cachedCity;
@end

@implementation CityManager

+ (instancetype)sharedInstance {
    static CityManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cachedCity = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYCachedCity"];
    }
    return self;
}

- (NSString *)currentCity {
    return _cachedCity ?: @"未知";
}

- (void)updateCity:(NSString *)city {
    _cachedCity = city;
    [[NSUserDefaults standardUserDefaults] setObject:city forKey:@"DYYYCachedCity"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
