//
//  CityManager.h
//  DYYY-Optimized
//

#import <Foundation/Foundation.h>

@interface CityManager : NSObject

+ (instancetype)sharedInstance;
- (NSString *)currentCity;
- (void)updateCity:(NSString *)city;

@end
