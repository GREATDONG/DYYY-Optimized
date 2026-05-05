//
//  DYYYManager.h
//  DYYY-Optimized
//
//  下载管理器 - 优化版
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, MediaType) {
    MediaTypeVideo,
    MediaTypeAudio,
    MediaTypeImage
};

@interface DYYYManager : NSObject

+ (instancetype)shared;

// 保存媒体到相册
+ (void)saveMedia:(NSURL *)mediaURL 
        mediaType:(MediaType)mediaType 
       completion:(void (^)(BOOL success))completion;

// 下载管理
- (void)downloadMediaWithURL:(NSString *)urlString
                   mediaType:(MediaType)mediaType
                  completion:(void (^)(BOOL success, NSURL *fileURL))completion;

// 批量下载
- (void)batchDownload:(NSArray<NSString *> *)urls
           completion:(void (^)(NSInteger successCount, NSInteger totalCount))completion;

// 取消下载
- (void)cancelDownload:(NSString *)downloadID;
- (void)cancelAllDownloads;

@end
