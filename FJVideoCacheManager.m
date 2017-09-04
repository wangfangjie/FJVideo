//
//  FJVideoCacheManager.m
//  FJVideo
//
//  Created by wangfj on 2017/8/21.
//  Copyright © 2017年 FJVideo. All rights reserved.
//

#import "FJVideoCacheManager.h"
#import "FMDB.h"

static FJVideoCacheManager *_defaultManager = nil;

@interface FJVideoCacheManager () <NSURLSessionDownloadDelegate>

/** 保存所有下载任务 --> 方便取消下载 */
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURLSessionDownloadTask *> *downloadTasksDic;

@end

@implementation FJVideoCacheManager

+ (void)load {
    [[FJVideoCacheManager sharedManager] createVedioCacheTable];
}

#pragma mark 清除缓存

+ (void)clearVideoCache {
    BOOL removeSucceed = [[NSFileManager defaultManager] removeItemAtPath:FJ_VIDEO_CACHE_DERECTORY error:nil];
    if (removeSucceed) {
        [[FJVideoCacheManager sharedManager] createVedioCacheTable];
    }
}

#pragma mark 获取缓存大小

+ (float)getSize {
    return [[FJVideoCacheManager sharedManager] folderSizeAtPath:FJ_VIDEO_CACHE_DERECTORY];
}

#pragma mark 获取文件夹大小

- (float)folderSizeAtPath:(NSString*)folderPath {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if (![manager fileExistsAtPath:folderPath]) return 0;
    
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    
    NSString *fileName = nil;
    
    long long folderSize = 0;
    
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        
        NSString *fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize/(1024.0*1024.0);
}

#pragma mark 获取文件大小

- (long long)fileSizeAtPath:(NSString*)filePath{
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if ([manager fileExistsAtPath:filePath]) {
        
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

#pragma mark 创建数据库和文件夹

- (void)createVedioCacheTable {
    
    BOOL isDirectory = NO;
    
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:FJ_VIDEO_CACHE_DERECTORY isDirectory:&isDirectory];
    
    if (!exist || !isDirectory) {
        
        [[NSFileManager defaultManager] createDirectoryAtPath:FJ_VIDEO_CACHE_DERECTORY withIntermediateDirectories:YES attributes:nil error:nil];
    }
    //    NSLog(@"%@", FJ_VIDEO_CACHE_DERECTORY);
    [[FMDatabaseQueue databaseQueueWithPath:FJ_VIDEO_CACHE_TABLE_PATH] inDatabase:^(FMDatabase *db) {
        
        NSString *sql = @"CREATE TABLE IF NOT EXISTS videoCacheTable(cacheDate DOUBLE NOT NULL, netUrl TEXT NOT NULL, localPath TEXT NOT NULL);";
        
        BOOL success = [db executeUpdate:sql];
        
        if (success) {
            //            NSLog(@"===== 创建视频缓存表成功 =====");
        }else {
            //            NSLog(@"===== 创建视频缓存表失败 =====");
        }
    }];
}

#pragma mark 将视频数据插入表

/**
 *  将视频数据插入表
 *
 *  @param urlStr    网络URL
 *  @param localPath 本地路劲
 *
 *  @return 插入是否成功
 */
- (BOOL)cacheVideoWithNetUrl:(nonnull NSString *)urlStr localPath:(nonnull NSString *)localPath {
    
    __block BOOL cacheSuccess = NO;
    
    /** 模糊判断是视频连接：以.mp4结尾 */
    if ([urlStr rangeOfString:@".mp4"].length > 0) {
        urlStr = [urlStr substringToIndex:[urlStr rangeOfString:@".mp4"].location + 4];
    }
    
    [[FMDatabaseQueue databaseQueueWithPath:FJ_VIDEO_CACHE_TABLE_PATH] inDatabase:^(FMDatabase *db) {
        
        NSDate *currentDate = [NSDate date];
        
        NSTimeInterval timeCount = [currentDate timeIntervalSince1970];
        
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO videoCacheTable (cacheDate, netUrl, localPath) VALUES('%f', '%@', '%@');", timeCount, urlStr, localPath];
        
        BOOL success = [db executeUpdate:sql];
        
        if (success) {
            
            cacheSuccess = YES;
            
            //            NSLog(@"===== 视频信息插入表成功 =====");
        }else {
            
            //            NSLog(@"===== 添加信息插入表失败 =====");
        }
    }];
    return cacheSuccess;
}

#pragma mark 通过网络URL判断文件是否有缓存

/**
 *  通过网络URL判断文件是否有缓存
 *
 *  @param netUrl 网络URL
 *
 *  @return 是否有缓存
 */
- (BOOL)videoExistWithNetUrl:(nonnull NSString *)netUrl completion:(nullable void (^)(NSString * __nullable))existBlock {
    
    /** 模糊判断是视频连接：以.mp4结尾 */
    if ([netUrl rangeOfString:@".mp4"].length > 0) {
        netUrl = [netUrl substringToIndex:[netUrl rangeOfString:@".mp4"].location + 4];
    }
    __block BOOL hasCache = NO;
    
    [[FMDatabaseQueue databaseQueueWithPath:FJ_VIDEO_CACHE_TABLE_PATH] inDatabase:^(FMDatabase *db) {
        
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM videoCacheTable WHERE netUrl='%@';", netUrl];
        
        FMResultSet *result = [db executeQuery:sql];
        
        while ([result next]) {
            
            BOOL isDirectory = NO;
            
            NSString *localPath = [result stringForColumn:@"localPath"];
            
            BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:localPath isDirectory:&isDirectory];
            if (exist && !isDirectory) {
                
                hasCache = YES;
                
                //                NSLog(@"===== 有本地缓存视频 =====");
                
                sql = [NSString stringWithFormat:@"UPDATE videoCacheTable SET cacheDate='%f' WHERE netUrl='%@';", [[NSDate date] timeIntervalSince1970], netUrl];
                
                [db executeUpdate:sql];
                
                if (existBlock) existBlock(localPath);
            }else {
                /** 如果本地没有文件了，删除记录 */
                sql = [NSString stringWithFormat:@"DELETE FROM videoCacheTable WHERE netUrl='%@';", netUrl];
                [db executeUpdate:sql];
            }
        }
        [result close];
    }];
    
    return hasCache;
}
#pragma mark 将下载完成的临时文件拷贝到缓存目录

/**
 *  将下载完成的临时文件拷贝到缓存目录
 *
 *  @param netUrl    网络URL
 *  @param videoPath 本地路劲
 *
 *  @return 是否拷贝成功
 */
- (BOOL)copyVideoWithNetUrl:(NSURL *)netUrl atPath:(NSString *)videoPath {
    
    NSString *realURLStr = @"";
    if (netUrl.absoluteString.length >[netUrl.absoluteString rangeOfString:@".mp4"].location + 4)
    {
        realURLStr  = [netUrl.absoluteString substringToIndex:[netUrl.absoluteString rangeOfString:@".mp4"].location + 4];
    }
    
    
    // 拼接视频文件路径
    NSString *movePath = FJ_VIDEO_PATH(realURLStr.lastPathComponent);
    
    // 判断是否已存在视频，存在就移除现有缓存
    if ([[NSFileManager defaultManager] fileExistsAtPath:movePath]) {
        
        [[NSFileManager defaultManager] removeItemAtPath:movePath error:nil];
        
        //        NSLog(@"===== 移除已有视频缓存 =====");
    }
    
    // 将临时视频拷贝到视频缓存目录并重命名
    BOOL isSuccess = [[NSFileManager defaultManager] copyItemAtPath:videoPath toPath:movePath error:nil];
    
    BOOL cacheSucceed = NO;
    
    if (isSuccess) {
        
        //        NSLog(@"===== 视频缓存成功 =====\n%@", movePath);
        
        // 拷贝成功，将scheme换回http
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:netUrl resolvingAgainstBaseURL:NO];
        
        components.scheme = @"http";
        
        NSURL *aUrl = components.URL;
        
        // 用视频缓存管理者将视频信息插入到表
        BOOL insertSuccess = [[FJVideoCacheManager sharedManager] cacheVideoWithNetUrl:aUrl.absoluteString localPath:movePath];
        
        cacheSucceed = insertSuccess;
    }
    return cacheSucceed;
}

#pragma mark - 下载视频

- (void)cacheVideoWithURL:(NSString *)url {
    
    NSURL *videoURL = [NSURL URLWithString:url];
    if (!videoURL) return;
    
    NSURLSessionDownloadTask *existTask = [self.downloadTasksDic objectForKey:url];
    
    if (existTask) {
        switch (existTask.state) {
            case NSURLSessionTaskStateCompleted:
                [self.downloadTasksDic removeObjectForKey:url];
                return;
                break;
            case NSURLSessionTaskStateRunning:
                return;
                break;
            case NSURLSessionTaskStateSuspended:
                [existTask resume];
                return;
                break;
            default:
                [self.downloadTasksDic removeObjectForKey:url];
                break;
        }
    }
    
    //    NSLog(@"下载视频:%@", url.lastPathComponent);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:videoURL];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
    
    [downloadTask resume];
    //    NSLog(@"cache url:%@", url);
    [self.downloadTasksDic setValue:downloadTask forKey:url];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    if (self.progressBlock) {
        self.progressBlock((float)totalBytesWritten / totalBytesExpectedToWrite);
    }
    //    NSLog(@"下载进度：%f", (float)totalBytesWritten / totalBytesExpectedToWrite);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    
    /** 完成后移除下载任务 */
    [self.downloadTasksDic removeObjectForKey:downloadTask.response.URL.absoluteString];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSURL *url = downloadTask.response.URL;
    
    [self.downloadTasksDic removeObjectForKey:url.absoluteString];
    
    NSString *MD5Str = [url.absoluteString componentsSeparatedByString:@"?"].lastObject;
    
    if (!MD5Str.length || [MD5Str rangeOfString:@"://"].length > 0) return;
    
    NSString *tempPath = location.path;
    
    NSString *fileMD5Str = [self fileMD5AtPath:tempPath];
    
    /** 此处用包含判断：因为测试和正式服务器返回的MD5参数字符串格式不统一 */
    if ([MD5Str rangeOfString:fileMD5Str].length < 1) return;
    
    [self copyVideoWithNetUrl:url atPath:location.path];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (task.response.URL.absoluteString.length && self.downloadTasksDic.count) {
        /** 失败移除下载任务 */
        [self.downloadTasksDic removeObjectForKey:task.response.URL.absoluteString];
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark 取消下载视频

- (void)cancelDownloadTaskWithURL:(NSString *)url {
    
    if (!url.length) return;
    
    NSURLSessionDownloadTask *downloadTask = [self.downloadTasksDic objectForKey:url];
    
    if (downloadTask) {
        if (downloadTask.state != NSURLSessionTaskStateCompleted) {
            [downloadTask cancel];
        }
        
        [self.downloadTasksDic removeObjectForKey:url];
        
        //        NSLog(@"取消下载:%@", url.lastPathComponent);
    }
}

#pragma mark 获取本地文件的MD5
/**
 *  获取本地文件的MD5
 *
 *  @param path 文件路径
 *
 *  @return MD5字符串
 */
- (NSString *)fileMD5AtPath:(NSString *)path {
    
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if( handle== nil ) return @"ERROR GETTING FILE MD5"; // file didnt exist
    
    CC_MD5_CTX md5;
    
    CC_MD5_Init(&md5);
    
    BOOL done = NO;
    while(!done) {
        
        NSData* fileData = [handle readDataOfLength:CHUNK_SIZE];
        
        CC_MD5_Update(&md5, [fileData bytes], (CC_LONG)[fileData length]);
        
        if( [fileData length] == 0 ) done = YES;
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5_Final(digest, &md5);
    
    NSString* MD5Str = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                        digest[0], digest[1],
                        digest[2], digest[3],
                        digest[4], digest[5],
                        digest[6], digest[7],
                        digest[8], digest[9],
                        digest[10], digest[11],
                        digest[12], digest[13],
                        digest[14], digest[15]];
    return MD5Str;
}


#pragma mark - 单例实现

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _defaultManager = [super allocWithZone:zone];
        
    });
    return _defaultManager;
}

+ (instancetype)sharedManager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultManager = [[FJVideoCacheManager alloc] init];
    });
    return _defaultManager;
}

- (id)copy {
    return _defaultManager;
}

- (id)mutableCopy {
    return _defaultManager;
}

#pragma mark - 懒加载/其他

- (NSMutableDictionary<NSString *,NSURLSessionDownloadTask *> *)downloadTasksDic {
    if (!_downloadTasksDic) {
        _downloadTasksDic = [NSMutableDictionary dictionary];
    }
    return _downloadTasksDic;
}

- (void)dealloc {
    //    NSLog(@"%s", __FUNCTION__);
}



@end















