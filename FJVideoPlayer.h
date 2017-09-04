//
//  SKVideoPlayer.h
//  FJVideo
//
//  Created by wangfj on 2017/8/21.
//  Copyright © 2017年 FJVideo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "FJVideoPublic.h"

// 播放器的几种状态
typedef NS_ENUM(NSInteger, FJPlayerState) {
    FJPlayerStateFailed,     // 播放失败
    FJPlayerStateBuffering,  // 缓冲中
    FJPlayerStatePlaying,    // 播放中
    FJPlayerStateStopped,    // 停止播放
    FJPlayerStatePause       // 暂停播放
};

@interface FJVideoPlayer : UIView

/*** 点击播放按钮 */
@property (nonatomic, copy  ) PlayBtnClickedBlock     playBtnClickedBlock;
/** 全屏按钮点击回调 */
@property (nonatomic, copy  ) FullScreenBlock         fullScreenBlock;
/** 分享按钮点击回调 */
@property (nonatomic, copy  ) ShareClickBlock         shareClickBlock;
/** 分享按钮点击回调 */
@property (copy, nonatomic  ) ShareBtnClickBlock      shareBtnClickBlock;
/** 返回按钮点击回调 */
@property (nonatomic, copy  ) BackClickBlock          backClickBlock;
@property (nonatomic, copy  ) FullScreenBackBlock     fullBackBlock;
/** 点击重播，回调统计播放次数 */
@property (copy, nonatomic  ) RepeatBtnClickBlock     repeatClickBlock;
/** 加载失败回调：需要将player设置为nil重新初始化一遍再播放 */
@property (copy, nonatomic  ) VideoDidLoadFailedBlock loadFailedBlock;
/** 回调播放时间 */
@property (copy, nonatomic  ) VideoTimeObserveBlock   timeObserveBlock;
/** 视频播放完成回调 */
@property (copy, nonatomic  ) VideoDidFinishedPlayBlock finishedBlock;
/** 点击滑动条 */
@property (nonatomic, copy  ) SliderTapBlock sliderTapBlock;
/** 滑动结束回调 */
@property (nonatomic, copy  ) SliderEndBlock sliderEndBlock;
/** 隐藏控制条回调 */
@property (copy, nonatomic  ) AnimateHideControlBarBlock controlBarHideBlock;
/** 播发器当前状态 */
@property (nonatomic, assign, readonly) FJPlayerState state;
/** 封面图 */
@property (nonatomic, strong) UIImage  *coverImage;
/** 视频URL */
@property (nonatomic, copy  ) NSString *videoURL;
/** 视频标题 */
@property (nonatomic, copy  ) NSString *videoTitle;
/** 是否循环播放 */
@property (nonatomic, assign) BOOL loopPlay;
/** 是否允许手势调整亮度 */
@property (nonatomic, assign) BOOL enableGesture;
/** 是否显示控制条 */
@property (nonatomic, assign) BOOL showControlBar;
@property (nonatomic, assign) BOOL showNavBar;
/** 是否静音 */
@property (nonatomic, assign) BOOL mute;
/** 播放自动全屏 */
@property (assign, nonatomic) BOOL isNotCellVideo;
/** 是否显示中心的播放按钮：在4G进入详情页时不会自动播放，将此属性设置为YES */
@property (assign, nonatomic) bool showCenterPlayBtn;
/** 当前播放时间 */
@property (assign, nonatomic) NSInteger currentTime;
@property (assign, nonatomic) NSUInteger seekTime;
/** 视频总时长 */
@property (nonatomic, strong) NSString  *totalTime;

/******************************************/

/** 自动播放 */
- (void)autoPlayVideo;

/** 销毁播放器 */
- (void)destroyPlayer;

/** 播放 */
- (void)play;

/** 暂停 */
- (void)pause;

/** 往前seconds秒播放 */
- (void)seekForward:(NSTimeInterval)seconds;

/** 后退seconds秒播放 */
- (void)seekReverse:(NSTimeInterval)seconds;


@end
