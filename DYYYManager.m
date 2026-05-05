//
//  DYYYManager.m
//  DYYY-Optimized
//
//  下载管理器实现 - 优化版
//  修复：添加 nil 检查，改进错误处理
//

#import "DYYYManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>
#import "DYYYToast.h"
#import "DYYYCompat.h"

@interface DYYYManager () <NSURLSessionDownloadDelegate>
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSURLSessionDownloadTask *> *downloadTasks;
@property(nonatomic, strong) NSMutableDictionary<NSString *, void (^)(BOOL success, NSURL *fileURL)> *completionBlocks;
@property(nonatomic, strong) NSOperationQueue *downloadQueue;
@property(nonatomic, strong) NSURLSession *downloadSession;
@end

@implementation DYYYManager

#pragma mark - 单例

+ (instancetype)shared {
    static DYYYManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _downloadTasks = [NSMutableDictionary dictionary];
        _completionBlocks = [NSMutableDictionary dictionary];
        
        _downloadQueue = [[NSOperationQueue alloc] init];
        _downloadQueue.maxConcurrentOperationCount = 3;
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _downloadSession = [NSURLSession sessionWithConfiguration:config 
                                                         delegate:self 
                                                    delegateQueue:_downloadQueue];
    }
    return self;
}

#pragma mark - 保存媒体

+ (void)saveMedia:(NSURL *)mediaURL 
        mediaType:(MediaType)mediaType 
       completion:(void (^)(BOOL success))completion {
    
    // 修复：添加 nil 检查
    if (!mediaURL || mediaURL.absoluteString.length == 0) {
        DYYYLogError(@"saveMedia: mediaURL is nil or empty");
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
        }
        return;
    }
    
    // 音频不保存到相册
    if (mediaType == MediaTypeAudio) {
        DYYYLog(@"Audio files are not saved to photo library");
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
        }
        return;
    }
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [DYYYToast showToast:@"请允许访问相册权限"];
                if (completion) completion(NO);
            });
            return;
        }
        
        // 保存图片
        if (mediaType == MediaTypeImage) {
            [self saveImage:mediaURL completion:completion];
        } 
        // 保存视频
        else if (mediaType == MediaTypeVideo) {
            [self saveVideo:mediaURL completion:completion];
        }
    }];
}

+ (void)saveImage:(NSURL *)imageURL completion:(void (^)(BOOL success))completion {
    UIImage *image = [UIImage imageWithContentsOfFile:imageURL.path];
    if (!image) {
        DYYYLogError(@"Failed to load image from: %@", imageURL);
        if (completion) completion(NO);
        return;
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCreationRequest creationRequestForAssetFromImage:image];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [DYYYToast showSuccessToast:@"图片已保存"];
            } else {
                DYYYLogError(@"Save image failed: %@", error);
                [DYYYToast showToast:@"保存失败"];
            }
            if (completion) completion(success);
        });
    }];
}

+ (void)saveVideo:(NSURL *)videoURL completion:(void (^)(BOOL success))completion {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [DYYYToast showSuccessToast:@"视频已保存"];
            } else {
                DYYYLogError(@"Save video failed: %@", error);
                [DYYYToast showToast:@"保存失败"];
            }
            if (completion) completion(success);
        });
    }];
}

#pragma mark - 下载管理

- (void)downloadMediaWithURL:(NSString *)urlString
                   mediaType:(MediaType)mediaType
                  completion:(void (^)(BOOL success, NSURL *fileURL))completion {
    
    if (!urlString || urlString.length == 0) {
        DYYYLogError(@"downloadMediaWithURL: urlString is nil or empty");
        if (completion) completion(NO, nil);
        return;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        DYYYLogError(@"downloadMediaWithURL: invalid URL string: %@", urlString);
        if (completion) completion(NO, nil);
        return;
    }
    
    NSString *downloadID = [[NSUUID UUID] UUIDString];
    
    if (completion) {
        self.completionBlocks[downloadID] = completion;
    }
    
    NSURLSessionDownloadTask *task = [self.downloadSession downloadTaskWithURL:url];
    self.downloadTasks[downloadID] = task;
    [task resume];
    
    DYYYLog(@"Started download: %@", downloadID);
}

- (void)batchDownload:(NSArray<NSString *> *)urls
           completion:(void (^)(NSInteger successCount, NSInteger totalCount))completion {
    
    if (!urls || urls.count == 0) {
        if (completion) completion(0, 0);
        return;
    }
    
    NSInteger total = urls.count;
    __block NSInteger successCount = 0;
    dispatch_group_t group = dispatch_group_create();
    
    for (NSString *url in urls) {
        dispatch_group_enter(group);
        [self downloadMediaWithURL:url 
                         mediaType:MediaTypeVideo 
                        completion:^(BOOL success, NSURL *fileURL) {
            if (success) successCount++;
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) completion(successCount, total);
    });
}

- (void)cancelDownload:(NSString *)downloadID {
    if (!downloadID) return;
    
    NSURLSessionDownloadTask *task = self.downloadTasks[downloadID];
    if (task) {
        [task cancel];
        [self.downloadTasks removeObjectForKey:downloadID];
        [self.completionBlocks removeObjectForKey:downloadID];
        DYYYLog(@"Cancelled download: %@", downloadID);
    }
}

- (void)cancelAllDownloads {
    for (NSURLSessionDownloadTask *task in self.downloadTasks.allValues) {
        [task cancel];
    }
    [self.downloadTasks removeAllObjects];
    [self.completionBlocks removeAllObjects];
    DYYYLog(@"Cancelled all downloads");
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session 
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    NSString *downloadID = nil;
    for (NSString *key in self.downloadTasks.allKeys) {
        if (self.downloadTasks[key] == downloadTask) {
            downloadID = key;
            break;
        }
    }
    
    if (!downloadID) return;
    
    // 移动到永久位置
    NSString *fileName = downloadTask.response.suggestedFilename ?: [[NSUUID UUID] UUIDString];
    NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory 
                                                                  inDomains:NSUserDomainMask] firstObject];
    NSURL *destinationURL = [documentsURL URLByAppendingPathComponent:fileName];
    
    [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:nil];
    NSError *error = nil;
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:destinationURL error:&error];
    
    BOOL success = (error == nil);
    
    void (^completion)(BOOL, NSURL *) = self.completionBlocks[downloadID];
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success, destinationURL);
        });
    }
    
    [self.downloadTasks removeObjectForKey:downloadID];
    [self.completionBlocks removeObjectForKey:downloadID];
}

- (void)URLSession:(NSURLSession *)session 
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    // 可以在这里添加进度回调
}

- (void)URLSession:(NSURLSession *)session 
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    if (error) {
        DYYYLogError(@"Download failed: %@", error);
        
        // 查找对应的 downloadID
        NSString *downloadID = nil;
        for (NSString *key in self.downloadTasks.allKeys) {
            if (self.downloadTasks[key] == task) {
                downloadID = key;
                break;
            }
        }
        
        if (downloadID) {
            void (^completion)(BOOL, NSURL *) = self.completionBlocks[downloadID];
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, nil);
                });
            }
            [self.downloadTasks removeObjectForKey:downloadID];
            [self.completionBlocks removeObjectForKey:downloadID];
        }
    }
}

@end
