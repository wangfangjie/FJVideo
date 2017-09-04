//
//  FJVideoCacheManager.h
//  FJVideo
//
//  Created by wangfj on 2017/8/21.
//  Copyright © 2017年 FJVideo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FJVideoPublic.h"

@interface FJVideoCacheManager : NSObject


/** 视频下载进度回调 */
@property (copy, nonatomic, nonnull) VideoDownloadProgressBlock progressBlock;

/** 单例 */
+ (nonnull instancetype)sharedManager;

/** 清理视频缓存 */
+ (void)clearVideoCache;

/** 返回缓存大小：单位M */
+ (float)getSize;

/**
 *  缓存视频
 *
 *  @param url 视频URL
 */
- (void)cacheVideoWithURL:(nonnull NSString *)url;

/**
 *  取消视频下载任务
 *
 *  @param url 视频URL
 */
- (void)cancelDownloadTaskWithURL:(nonnull NSString *)url;

/**
 *  视频URL判断本地是否有缓存
 *
 *  @param netUrl     视频网络地址
 *  @param existBlock 当存在缓存时返回本地目录(使用lastPathComponent拼接本地路径带有MD5不准确，需要block返回)
 *
 *  @return 是否存在缓存，YES存在
 */
- (BOOL)videoExistWithNetUrl:(nonnull NSString *)netUrl completion:(nullable void(^)(NSString * __nullable localPath))existBlock;




@end
