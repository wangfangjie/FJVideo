//
//  Header.h
//  FJVideo
//
//  Created by wangfj on 2017/8/21.
//  Copyright © 2017年 FJVideo. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIFont+FJVideoFont.h"

/** 视频缓存文件夹 */
#define FJ_VIDEO_CACHE_DERECTORY [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"MyTempVideo"]

/** 视频信息数据库路径 */
#define FJ_VIDEO_CACHE_TABLE_PATH [FJ_VIDEO_CACHE_DERECTORY stringByAppendingPathComponent:@"videoCacheTable.db"]

/** 视频缓存路径 */
#define FJ_VIDEO_PATH(URLStr) [FJ_VIDEO_CACHE_DERECTORY stringByAppendingPathComponent:URLStr]

/** 转换Bundle图片名 */
#define FJ_BUNDLE_IMAGE_NAME(imageName) imageName//[@"FJVideoPlayer.bundle" stringByAppendingPathComponent:imageName]

/** 播放/全屏按钮宽度 */
#define FJ_PLAY_FULL_BTN_WIDTH (40.f)

/** 当前时间/总时间宽度 */
#define FJ_TIME_LABEL_WIDTH ([@"00:00" boundingRectWithSize:CGSizeMake(MAXFLOAT, 12) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:10.1f]} context:nil].size.width + 1)

#define _iOSVersionBigger(x)  (NSFoundationVersionNumber >= (x) - 0.0001)
#define IOS8_2_OR_LATER       _iOSVersionBigger(NSFoundationVersionNumber_iOS_8_2)

#define _FONTDBMLight(x)      [UIFont dbmFontOfLight:(x) weight:(- 1)]
#define _FONTDBMRegular(x)    [UIFont dbmFontOfRegular:(x) weight:(- 1)]
#define _FONTDBMBold(x)       [UIFont dbmFontOfBold:(x) weight:(- 1)]

#ifndef CBLCopyApplication
#warning 正包需要改到0，副包需要改到1

#define CBLCopyApplication          1       // 正包需要改到0，副包需要改到1

#endif

/** 分享按钮类型 */
typedef NS_ENUM(NSUInteger, FJVideoShareBtnType) {
    FJVideoShareBtnTypeWechat,
    FJVideoShareBtnTypeMoments,
    FJVideoShareBtnTypeQQ,
    FJVideoShareBtnTypeQzone,
    FJVideoShareBtnTypeWeiBo
};

/** 控制条自动隐藏时间 */
static const CGFloat FJ_AUTO_FATE_CONTROL_BAR_TIMEINTERVAL = 3.0f;

/** 控制条隐藏动画执行时间 */
static const CGFloat FJ_CONTROL_BAR_ANIMATION_TIMEINTERVAL = 0.25f;


typedef void (^PlayBtnClickedBlock)();
/** 全屏按钮点击回调 */
typedef void (^FullScreenBlock)(BOOL isFullScreen);

/** 返回按钮点击回调 */
typedef void (^BackClickBlock)();

typedef void (^FullScreenBackBlock)();

/** 分享按钮点击回调 */
typedef void (^ShareClickBlock)();

/** 进度滑块点击回调 */
typedef void (^SliderTapBlock)(CGFloat value);

/** 进度滑块滑动结束回调 */
typedef void (^SliderEndBlock)();

/** 视频下载进度回调 */
typedef void (^VideoDownloadProgressBlock)(float progress);

/** 分享按钮点击回调 */
typedef void (^ShareBtnClickBlock)(FJVideoShareBtnType btnType);

/** 视频加载失败 */
typedef void (^VideoDidLoadFailedBlock)();

/** 点击重播，回调统计播放次数 */
typedef void (^RepeatBtnClickBlock)();

/** 播放时间回调 */
typedef void(^VideoTimeObserveBlock)(NSTimeInterval currentPlayTime);

/** 视频播放结束回掉 */
typedef void(^VideoDidFinishedPlayBlock)();

/** 隐藏控制条block，供外部做其他隐藏 */
typedef void(^AnimateHideControlBarBlock)(BOOL isHide);

#define __WEAK_SELF_FJ_VIDEO_PLAYER __weak typeof(self) weakSelf = self;


/** MD5相关 */
typedef uint32_t CC_LONG;       /* 32 bit unsigned integer */
typedef uint64_t CC_LONG64;     /* 64 bit unsigned integer */

#define CC_MD5_DIGEST_LENGTH    16          /* digest length in bytes */
#define CC_MD5_BLOCK_BYTES      64          /* block size in bytes */
#define CC_MD5_BLOCK_LONG       (CC_MD5_BLOCK_BYTES / sizeof(CC_LONG))

typedef struct CC_MD5state_st {
    CC_LONG A,B,C,D;
    CC_LONG Nl,Nh;
    CC_LONG data[CC_MD5_BLOCK_LONG];
    int num;
} CC_MD5_CTX;

extern int CC_MD5_Init(CC_MD5_CTX *c)
__OSX_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_2_0);

extern int CC_MD5_Update(CC_MD5_CTX *c, const void *data, CC_LONG len)
__OSX_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_2_0);

extern int CC_MD5_Final(unsigned char *md, CC_MD5_CTX *c)
__OSX_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_2_0);

extern unsigned char *CC_MD5(const void *data, CC_LONG len, unsigned char *md)
__OSX_AVAILABLE_STARTING(__MAC_10_4, __IPHONE_2_0);

static const int32_t CHUNK_SIZE = 8 * 1024;
