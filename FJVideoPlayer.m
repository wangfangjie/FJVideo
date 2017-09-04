//
//  FJVideoPlayer.m
//  FJVideo
//
//  Created by wangfj on 2017/8/21.
//  Copyright © 2017年 FJVideo. All rights reserved.
//

#import "FJVideoPlayer.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Masonry.h"
#import "FJVideoCacheManager.h"
#import "FJVideoNaviBar.h"
#import "FJVideoControlBar.h"
//#import "FJVideoShareView.h"

// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger , FJPanDirection) {
    FJPanDirectionHorizontal, // 横向移动
    FJPanDirectionVertical    // 纵向移动
};

@interface FJVideoPlayer () <UIGestureRecognizerDelegate>

/** 播放属性 */
@property (nonatomic, strong) AVPlayer                *player;
@property (nonatomic, weak  ) AVPlayerLayer           *playerLayer;
@property (nonatomic, strong) AVPlayerItem            *playerItem;
@property (nonatomic, strong) AVURLAsset              *urlAsset;

/** 播放进度检测观察者(方便释放避免内存泄露) */
@property (nonatomic, strong) id                      timeObserve;

/** 播发器当前状态 */
@property (nonatomic, assign) FJPlayerState           state;

/*********************************************************************/
/** 视频封面图 */
@property (nonatomic, strong) UIImageView             *coverImageView;
/** navi控制条 */
@property (nonatomic, strong) FJVideoNaviBar          *naviStatusBar;
/** 控制条 */
@property (nonatomic, strong) FJVideoControlBar       *controlBar;
/** 显示快进/退和加载失败 */
@property (nonatomic, strong) UILabel                 *horizontalLabel;
/** 加载动画图片 */
@property (strong, nonatomic) UIImageView             *loadingImageView;
/** 亮度指示器 */
@property (nonatomic, strong) UIProgressView          *BrightnessProgress;
/** 亮度图片 */
@property (nonatomic, strong) UIImageView             *brightnessIconView;
/** 滑杆 */
@property (nonatomic, strong) UISlider                *volumeViewSlider;
/** 重播 */
@property (nonatomic, strong) UIButton                *playAginBtn;
/** 分享view */
//@property (strong, nonatomic) FJVideoShareView        *shareView;
/** 中间的播放按钮 */
@property (strong, nonatomic) UIButton                *centerPlayBtn;
/** 中间的暂停按钮，视频播放中点击此按钮暂停 */
@property (strong, nonatomic) UIButton                *centerPauseBtn;
/** 详情页隐藏音量图标 */
@property (strong, nonatomic) MPVolumeView            *volumView;

/*********************************************************************/
/** 定义一个实例变量，保存枚举值 */
@property (nonatomic, assign) FJPanDirection          panDirection;
/** 是否是调节音量 */
//@property (nonatomic, assign) BOOL                    isVolume;
/** 是否被用户暂停 */
@property (nonatomic, assign) BOOL                    isPauseByUser;
/** 播放完了 */
@property (nonatomic, assign) BOOL                    playDidEnd;
/** 是否播放本地文件 */
@property (nonatomic, assign) BOOL                    isLocalVideo;
/** 是否显示controlBar */
@property (nonatomic, assign) BOOL                    isControlBarShowing;
/** 进入后台 */
@property (nonatomic, assign) BOOL                    didEnterBackground;
/** 第一次播放：非重播，用于自动全屏和隐藏封面 */
@property (assign, nonatomic) BOOL                    isFirstPlay;
/** 记录快进快退(点击，拖动，手势快进退)：调度菊花动画；防止拖动后timeObserver期间更新slider导致slider滑块回跳 */
@property (assign, nonatomic) BOOL                    didSeekPlayTime;
/** 在还没加载完之前点击了暂停按钮 */
@property (assign, nonatomic) BOOL                    pausedBeforeReady;

/*********************************************************************/

/** 用来保存快进的总时长 */
@property (nonatomic, assign) CGFloat                 sumTime;
/** slider上次的值 */
@property (nonatomic, assign) CGFloat                 sliderLastValue;

/*********************************************************************/

/** 点击手势：隐藏/显示控制条 */
@property (nonatomic, strong) UITapGestureRecognizer  *tap;
/** 快进/退，调整亮度 */
@property (nonatomic, strong) UIPanGestureRecognizer  *pan;

@end

@implementation FJVideoPlayer

#pragma mark -
#pragma mark >>>>>>>>>> 播放器相关 <<<<<<<<<<
#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        /** 为了隐藏系统的音量HUD */
        MPVolumeView *volumeView = [[MPVolumeView alloc] init];
        _volumView = volumeView;
        [self insertSubview:volumeView atIndex:0];
        /** 默认情况下不隐藏系统音量图标：cell的video */
        volumeView.hidden = YES;
        [volumeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(50);
            make.top.mas_equalTo(-1000);
            make.left.mas_equalTo(-1000);
        }];
        
        self.backgroundColor = [UIColor colorWithRed:0.898 green:0.902 blue:0.910 alpha:1.000];
        /** 取消自动转换AutoresizingMask为约束 */
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        /** 封面图 */
        UIImageView *coverImgView = [[UIImageView alloc] init];
        coverImgView.backgroundColor = [UIColor clearColor];
        _coverImageView = coverImgView;
        [self addSubview:coverImgView];
        
        UIButton *playAginBtn = [UIButton new];
        [playAginBtn setImage:[UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_repeat_video")] forState:UIControlStateNormal];
        playAginBtn.backgroundColor = [UIColor clearColor];
        _playAginBtn = playAginBtn;
        [self addSubview:playAginBtn];
        
        UIButton *centerPlayBtn = [[UIButton alloc] init];
        centerPlayBtn.backgroundColor = [UIColor clearColor];
        _centerPlayBtn = centerPlayBtn;
        
        UIButton *centerPauseBtn = [[UIButton alloc]init];
        centerPauseBtn.backgroundColor = [UIColor clearColor];
        _centerPauseBtn = centerPauseBtn;
        _centerPauseBtn.hidden = !_centerPlayBtn.hidden;
        
        /** 添加控制条 */
        FJVideoControlBar *controlBar = [FJVideoControlBar new];
        _controlBar = controlBar;
        _controlBar.slider.userInteractionEnabled = NO;
        [self addSubview:controlBar];
        
        /** 一开始不能点击播放 */
        //        controlBar.playBtn.enabled = NO;
        
        /** 导航状态条 */
        FJVideoNaviBar *naviBar = [FJVideoNaviBar new];
        _naviStatusBar = naviBar;
        [self addSubview:naviBar];
        
        /** 获取系统音量slider */
        //        [self getVolumeSlider];
        
        /** 添加Label，菊花 */
        [self addSubview:self.horizontalLabel];
        [self addSubview:self.loadingImageView];
        [self addSubview:self.BrightnessProgress];
        [self addSubview:self.brightnessIconView];
//        [self addSubview:self.shareView];
        [self addSubview:self.centerPlayBtn];
        [self addSubview:self.centerPauseBtn];
        
        //TODO
        UIImageView *centerPlayBackground = [UIImageView new];
        centerPlayBackground.userInteractionEnabled = YES;
        centerPlayBackground.tag          = 100;
        [centerPlayBackground setBackgroundColor:[UIColor clearColor]];
        centerPlayBackground.image        = [UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_play_placeholder")];
        [_centerPlayBtn addSubview:centerPlayBackground];
        
        /** 约束 */
        [coverImgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(0);
        }];
        
        [playAginBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(40.f, 60.f));
            make.center.mas_equalTo(self);
        }];
        
        [centerPlayBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(50.f);
            make.center.mas_equalTo(self);
        }];
        [centerPauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(centerPlayBtn);
        }];
        
        [centerPlayBackground mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(UIEdgeInsetsMake(5, 5, 5, 5));
        }];
        
        [controlBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.mas_equalTo(0);
            make.height.mas_equalTo(40.f);
        }];
        
        [naviBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.mas_equalTo(0);
            make.height.mas_equalTo(45.f);
        }];
        
        [self.horizontalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(150.f);
            make.height.mas_equalTo(33.f);
            make.center.equalTo(self);
        }];
        
        [self.loadingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(38.f);
            make.center.mas_equalTo(self);
        }];
        
        CGFloat brightnessH = 70.f;
        
        [self.BrightnessProgress mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(-20.f);
            make.height.mas_equalTo(2);
            make.width.mas_equalTo(brightnessH);
            make.centerY.mas_equalTo(self);
        }];
        
        [self.brightnessIconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(self.BrightnessProgress);
            make.top.mas_equalTo(self.BrightnessProgress.mas_centerY).offset(brightnessH * 0.5 + 1);
            make.size.mas_equalTo(20.f);
        }];
        
//        [self.shareView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.edges.mas_equalTo(0);
//        }];
        
        /** 默认支持手势 */
        self.enableGesture = YES;
        
        // 添加手势
        [self addGesture];
        
        /** 隐藏亮度指示器 */
        [self hideBrightnessIndicator];
        
        /** 一开始隐藏重播 */
        playAginBtn.hidden = YES;
        
        /** 第一次播放 */
        self.isFirstPlay = YES;
        
        /** 默认是停止播放 */
        self.state = FJPlayerStateStopped;
        
        // 添加按钮点击事件
        [self addInteractiveTargets];
    }
    return self;
}
#pragma mark 准备player，创建初始化各类参数
- (void)preparePlayer {
    /** 防止未调用destroyPlayer后调用autoPlayerVideo时出现多个声音画面 */
    if (self.player || self.playerLayer) [self destroyPlayer];
    NSURL *videoUrl = [NSURL URLWithString:self.videoURL];
    self.urlAsset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.urlAsset];
    self.player     = [AVPlayer playerWithPlayerItem:self.playerItem];
    /** 本地文件播放 */
    if ([self.videoURL rangeOfString:@"file://"].length) {
        self.isLocalVideo = YES;
    }else{
        self.state = FJPlayerStateBuffering;
        self.isLocalVideo = NO;
        [[FJVideoCacheManager sharedManager] cacheVideoWithURL:self.videoURL];
    }
    /** 是否静音 */
    self.player.muted = self.mute;
    
    // 初始化playerLayer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
    // 此处为默认视频填充模式
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    // 添加playerLayer到self.layer
    [self.layer insertSublayer:self.playerLayer atIndex:0];
    
    // 初始化显示controlView为YES
    self.isControlBarShowing = YES;
    
    // 延迟隐藏controlView
    [self autoFadeOutControlBar];
    // 监控播放进度
    [self addPeriodicTimeObserver];
    // 开始播放
    [self play];
    // 重新加载播放的时候把快进快退label的背景色改回半透明
    self.horizontalLabel.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_mask_background")]];
    
    /** 重新添加通知 */
    [self addNotifications];
    
    // 如果不调用，当调用destroyPlayer之后再调用autoPlayVideo会导致playerLayer的Frame为空，视频黑屏
    [self setNeedsLayout];
    [self layoutIfNeeded];
}
#pragma mark 自动播放

- (void)autoPlayVideo {
    self.horizontalLabel.hidden = YES;
    [self preparePlayer];
}
#pragma mark 播放

- (void)play {
    self.isPauseByUser = NO;
    self.controlBar.playBtn.selected = YES;
    [_player play];
}
#pragma mark 暂停

- (void)pause {
    /** 如果此时播放以及结束了，还暂停个屁啊 */
    if (self.playDidEnd) return;
    
    self.isPauseByUser = YES;
    self.controlBar.playBtn.selected = NO;
    if (self.player.status != AVPlayerStatusFailed && self.state != FJPlayerStateFailed && self.state != FJPlayerStateStopped) {
        self.pausedBeforeReady = YES;
    }
    if (self.state != FJPlayerStateFailed) {
        self.state = FJPlayerStatePause;
    }
    [_player pause];
}

#pragma mark -
#pragma mark >>>>>>>>>> 添加各类通知 / 手势 <<<<<<<<<<
#pragma mark -
#pragma mark 添加播放进度时间监控
- (void)addPeriodicTimeObserver {
    
    __WEAK_SELF_FJ_VIDEO_PLAYER
    self.timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:nil usingBlock:^(CMTime time){
        
        AVPlayerItem *currentItem = weakSelf.playerItem;
        
        NSArray *loadedRanges = currentItem.seekableTimeRanges;
        
        if (weakSelf.timeObserveBlock) {
            weakSelf.timeObserveBlock((NSTimeInterval)currentItem.currentTime.value / currentItem.currentTime.timescale);
        }
        
        if (loadedRanges.count > 0 && currentItem.duration.timescale != 0) {
            
            /** 此处一定要用round函数取四舍五入整数得到当前时间，直接强转会丢掉精确率导致获得时间会回跳1秒，界面显示时就是BUG了 */
            NSInteger currentTime = (NSInteger)round(CMTimeGetSeconds([currentItem currentTime]));
            CGFloat totalTime     = (CGFloat)currentItem.duration.value / currentItem.duration.timescale;
            
            if (weakSelf.isFirstPlay) {
                
                /** 加载完毕自动全屏 */
                //                if (weakSelf.isNotCellVideo && !weakSelf.controlBar.fullScreenBtn.selected) [weakSelf fullScreenClick:weakSelf.controlBar.fullScreenBtn];
                
                weakSelf.coverImageView.hidden = YES;
                
                weakSelf.isFirstPlay = NO;
            }
            
            /** 播放时才会进入监听block，在这里设置播放状态最佳：可以防止在KVO state -> readyToplay 时隐藏封面过早导致黑屏，快进时隐藏菊花太早导致卡顿 */
            if (!weakSelf.didSeekPlayTime && weakSelf.controlBar.playBtn.selected) weakSelf.state = FJPlayerStatePlaying;
            
            // 当前时长进度progress
            NSInteger proMin  = currentTime / 60;//当前秒
            NSInteger proSec  = currentTime % 60;//当前分钟
            // duration 总时长
            NSInteger durMin  = (NSInteger)totalTime / 60;//总秒
            NSInteger durSec  = (NSInteger)totalTime % 60;//总分钟
            
            // 如果没有在拖动slider，则更新slider
            if (!weakSelf.didSeekPlayTime) {
                weakSelf.controlBar.slider.value      = CMTimeGetSeconds([currentItem currentTime]) / totalTime;
            }
            // 更新当前播放时间
            weakSelf.controlBar.currentTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
            // 更新总时间
            weakSelf.controlBar.totalTimeLabel.text   = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
        }
    }];
}

#pragma mark 添加观察者监听各类通知

- (void)addNotifications {
    
    // APP退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    
    // APP进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeGround) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // 监听耳机插入和拔掉通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
}

#pragma mark 添加各类BUTTON的点击事件

- (void)addInteractiveTargets {
    [self.playAginBtn addTarget:self action:@selector(playAginBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.centerPlayBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.centerPauseBtn addTarget:self action:@selector(pause) forControlEvents:UIControlEventTouchUpInside];
    
    [self.naviStatusBar.backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.naviStatusBar.shareBtn addTarget:self action:@selector(shareBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    // slider开始滑动事件
    [self.controlBar.slider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    
    // slider滑动中事件
    [self.controlBar.slider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    // slider结束滑动事件
    [self.controlBar.slider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    
    // 播放按钮点击事件
    [self.controlBar.playBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    // 全屏按钮点击事件
    [self.controlBar.fullScreenBtn addTarget:self action:@selector(fullScreenClick:) forControlEvents:UIControlEventTouchUpInside];
    
    // 点击slider快进
    __WEAK_SELF_FJ_VIDEO_PLAYER
    self.controlBar.tapBlock = ^(CGFloat value) {
        
        weakSelf.didSeekPlayTime = YES;
        
        [weakSelf pause];
        
        // 视频总时间长度
        CGFloat total = (CGFloat)weakSelf.playerItem.duration.value / weakSelf.playerItem.duration.timescale;
        
        //计算出拖动的当前秒数
        NSInteger dragedSeconds = floorf(total * value);
        
        /** 跳转播放点 */
        [weakSelf seekToTime:dragedSeconds completionHandler:^(BOOL finished) {
            weakSelf.didSeekPlayTime = NO;
        }];
    };
}

#pragma mark 添加 tap 手势

- (void)addGesture {
    
    self.tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
    [self addGestureRecognizer:self.tap];
    
    // 解决点击当前view时候响应其他控件事件
    self.tap.delaysTouchesBegan = YES;
}

#pragma mark 获得系统音量调节view
/**
 *  获取系统音量
 */
- (void)getVolumeSlider {
    
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    volumeView.showsVolumeSlider = NO;
}

#pragma mark -
#pragma mark >>>>>>>>>> 缓冲进度相关 <<<<<<<<<<
#pragma mark -

#pragma mark 缓冲较差时候，加载一定时间

- (void)bufferingSomeSecond {
    
    if (self.isFirstPlay) return;
    
    self.state = FJPlayerStateBuffering;
    
    // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
    //    static BOOL isBuffering = NO;
    //    if (isBuffering) return;
    //    isBuffering = YES;
    
    if (self.isPauseByUser) {
        //        isBuffering = NO;
        return;
    }
    
    // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
    [self.player pause];
    
    NSTimeInterval loadedSeconds = [self availableDuration];
    NSTimeInterval currentTime = [self currentTime];
    
    /** 加载满进度 或 加载长度已经够9.5s了，开始播放 */
    if (self.playerItem.isPlaybackBufferFull || (self.playerItem.isPlaybackLikelyToKeepUp && loadedSeconds - currentTime > 9.5f)) {
        [self play];
        
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
        //        isBuffering = NO;
    }
    
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //
    //        // 如果此时用户已经暂停了，则不再需要开启播放了
    //        if (self.isPauseByUser) {
    //            isBuffering = NO;
    //            return;
    //        }
    //
    //        [self play];
    //
    //        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
    //        isBuffering = NO;
    //
    //        if (!self.playerItem.isPlaybackLikelyToKeepUp) [self bufferingSomeSecond];
    //    });
}
#pragma mark 计算缓冲进度

- (NSTimeInterval)availableDuration {
    
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    
    return result;
}

#pragma mark 跳转视频播放点

/**
 *  从xx秒开始播放视频跳转
 *
 *  @discussion seekTime:completionHandler:不能精确定位,如果需要精确定位，可以使用seekToTime:toleranceBefore:toleranceAfter:completionHandler:
 *
 *  @param dragedSeconds 视频跳转的秒数
 */
- (void)seekToTime:(NSInteger)dragedSeconds completionHandler:(void (^)(BOOL finished))completionHandler {
    if (!self.playDidEnd) {
        self.state = FJPlayerStateBuffering;
    }
    
    self.controlBar.playBtn.selected = YES;
    
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        
        // 转换成CMTime才能给player来控制播放进度
        CMTime dragedCMTime = CMTimeMake(dragedSeconds, 1);
        
        [self.player seekToTime:dragedCMTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            
            // 视频跳转回调
            if (completionHandler) completionHandler(finished);
            
            [self play];
        }];
    }
}
#pragma mark 往前seconds秒播放

- (void)seekForward:(NSTimeInterval)seconds {
    
    NSTimeInterval totalTime = CMTimeGetSeconds(self.playerItem.duration);
    
    NSInteger currentTime = (NSInteger)round(CMTimeGetSeconds([self.playerItem currentTime]));
    
    /** 剩余时间 > 快进的时间直接快进，否则快进到最后 */
    if (totalTime - currentTime > seconds) {
        
        [self seekToTime:currentTime + seconds completionHandler:nil];
    }else {
        
        [self seekToTime:totalTime completionHandler:nil];
    }
    [self pause];
}

#pragma mark 后退seconds秒播放

- (void)seekReverse:(NSTimeInterval)seconds {
    
    NSInteger currentTime = (NSInteger)round(CMTimeGetSeconds([self.playerItem currentTime]));
    
    /** 当前时间 > 后退的时间直接后退，否则退到0秒 */
    if (currentTime > seconds) {
        
        [self seekToTime:currentTime - seconds completionHandler:nil];
        
    }else {
        
        [self seekToTime:0.0 completionHandler:nil];
    }
    [self pause];
}

#pragma mark -
#pragma mark >>>>>>>>>> 交互事件响应 <<<<<<<<<<
#pragma mark -

#pragma mark 播放按钮点击

- (void)playBtnClick:(UIButton *)button {
    
    self.controlBar.playBtn.selected = !self.controlBar.playBtn.selected;
    
    self.pausedBeforeReady = NO;
    
    if (self.controlBar.playBtn.selected) {
        
        self.showCenterPlayBtn = NO;
        if (!self.player) {
            [self autoPlayVideo];
        }else {
            [self play];
            [self autoFadeOutControlBar];
        }
        if (self.playBtnClickedBlock) {
            self.playBtnClickedBlock();
        }
        
    } else {
        
        [self pause];
        /** 暂停时取消自动隐藏控制条 */
        [self cancelAutoFadeOutControlBar];
    }
}
#pragma mark 全屏按钮点击

- (void)fullScreenClick:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    
    self.naviStatusBar.fullScreen = sender.selected;
    
    if (self.fullScreenBlock) {
        self.fullScreenBlock(sender.selected);
    }
    if (self.fullBackBlock) self.fullBackBlock();
    
    [self.controlBar setNeedsUpdateConstraints];
    [self.controlBar updateConstraintsIfNeeded];
    [self.controlBar layoutIfNeeded];
}

#pragma mark 返回按钮点击

- (void)backBtnClick:(UIButton *)sender {
    
    if (self.controlBar.fullScreenBtn.selected) {
        
        [self fullScreenClick:self.controlBar.fullScreenBtn];
        return;
    }
    if (self.backClickBlock) self.backClickBlock();
}
#pragma mark 分享按钮点击

- (void)shareBtnClick:(UIButton *)sender {
    
    if (self.controlBar.fullScreenBtn.selected) {
//        [self animateHideControlBar];
//        [self showShareView];
        return;
    }
    if (self.shareClickBlock) self.shareClickBlock();
}

- (void)playAginBtnClick:(UIButton *)sender {
    
    sender.hidden = YES;
    
    self.isFirstPlay = YES;
    
    // 没有播放完
    self.playDidEnd = NO;
    
    // 准备显示控制层
    self.isControlBarShowing = NO;
    
    [self animateShowControlBar];
    
    // 重置控制层View
    [self.controlBar resetControlView];
    
    /** 跳转到0秒开始播放 */
    __WEAK_SELF_FJ_VIDEO_PLAYER
    [self seekToTime:0 completionHandler:^(BOOL finished) {
        
        if (weakSelf.repeatClickBlock) weakSelf.repeatClickBlock();
    }];
}

#pragma mark slider开始滑动

- (void)progressSliderTouchBegan:(UISlider *)slider {
    
    self.horizontalLabel.hidden = NO;
    self.didSeekPlayTime = YES;
    // 暂停
    [self pause];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark slider滑动中

- (void)progressSliderValueChanged:(UISlider *)slider {
    
    //拖动改变视频播放进度
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        
        /** 得到快进还是快退生成 */
        NSString *style = @"";
        CGFloat value   = slider.value - self.sliderLastValue;
        if (value > 0) style = @">>";
        if (value < 0) style = @"<<";
        if (value == 0) return;
        
        /** 记录最后拖动进度 */
        self.sliderLastValue    = slider.value;
        
        // 总时长
        CGFloat total           = (CGFloat)_playerItem.duration.value / _playerItem.duration.timescale;
        
        //计算出拖动的当前秒数
        NSInteger dragedSeconds = floorf(total * slider.value);
        
        //转换成CMTime才能给player来控制播放进度
        CMTime dragedCMTime     = CMTimeMake(dragedSeconds, 1);
        
        // 拖拽的时长
        NSInteger proMin        = (NSInteger)CMTimeGetSeconds(dragedCMTime) / 60;//当前秒
        NSInteger proSec        = (NSInteger)CMTimeGetSeconds(dragedCMTime) % 60;//当前分钟
        
        
        //duration 总时长
        NSInteger durMin        = (NSInteger)total / 60;//总秒
        NSInteger durSec        = (NSInteger)total % 60;//总分钟
        
        NSString *currentTime   = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
        NSString *totalTime     = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
        
        if (total > 0) { // 当总时长 > 0 的时候才能拖动slider
            
            self.controlBar.currentTimeLabel.text = currentTime;
            self.horizontalLabel.hidden = NO;
            self.horizontalLabel.text = [NSString stringWithFormat:@"%@ %@ / %@",style, currentTime, totalTime];
        }else {
            
            // 此时设置slider值为0
            slider.value = 0;
        }
        
        if (self.sliderTapBlock) {
            self.sliderTapBlock(slider.value);
        }
    }else {
        // player状态加载失败，设置slider值为0
        slider.value = 0;
    }
}
#pragma mark slider滑动结束

- (void)progressSliderTouchEnded:(UISlider *)slider {
    
    self.horizontalLabel.hidden = YES;
    
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        
        // 结束滑动时候把开始播放按钮改为播放状态
        self.controlBar.playBtn.selected = YES;
        
        self.isPauseByUser = NO;
        
        // 滑动结束延时隐藏controlBar
        [self autoFadeOutControlBar];
        
        // 视频总时间长度
        CGFloat total = (CGFloat)_playerItem.duration.value / _playerItem.duration.timescale;
        
        //计算出拖动的当前秒数
        NSInteger dragedSeconds = floorf(total * slider.value);
        
        /** 跳转播放点 */
        __WEAK_SELF_FJ_VIDEO_PLAYER
        [self seekToTime:dragedSeconds completionHandler:^(BOOL finished) {
            weakSelf.didSeekPlayTime = NO;
        }];
        
        if (self.sliderEndBlock) {
            self.sliderEndBlock();
        }
        
    }else self.didSeekPlayTime = NO;
}

#pragma mark tap点击手势事件

- (void)tapAction:(UITapGestureRecognizer *)gesture {
    
    if (self.playDidEnd) return;
    
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        
        self.isControlBarShowing ? ([self animateHideControlBar]) : ([self animateShowControlBar]);
    }
    
    /** 单独判断加载失败不准确，再判断Label的text和显示状态 */
    if (self.state == FJPlayerStateFailed || (self.horizontalLabel.hidden == NO && [self.horizontalLabel.text isEqualToString:@"加载失败，点击重试"])) {
        [self destroyPlayer];
        [self autoPlayVideo];
    }
}

#pragma mark pan手势事件

- (void)panAction:(UIPanGestureRecognizer *)pan {
    
    if (self.playDidEnd) return;
    
    //根据在view上Pan的位置，确定是调音量还是亮度
    //    CGPoint locationPoint = [pan locationInView:self];
    
    // 我们要响应水平移动和垂直移动
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self];
    //    float volume = self.volumeViewSlider.value;
    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: { // 开始移动
            
            /** 取消自动隐藏控制条 */
            [self cancelAutoFadeOutControlBar];
            
            /** 滑动手势的时候显示控制条 */
            [self animateShowControlBar];
            
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            
            if (x > y) { // 水平移动
                
                // 取消隐藏
                self.horizontalLabel.hidden = NO;
                self.panDirection = FJPanDirectionHorizontal;
                
                self.didSeekPlayTime = YES;
                
                // 给sumTime初值
                CMTime time       = self.player.currentTime;
                self.sumTime      = time.value/time.timescale;
                
                // 暂停视频播放
                [self pause];
                
                /** 快进快退手势滑动时，先停止加载 */
                [self stopLoading];
                
            } else if (x < y) { // 垂直移动
                
                self.panDirection = FJPanDirectionVertical;
                
                // 开始滑动的时候,状态改为正在控制音量
                //                if (locationPoint.x > self.bounds.size.width * 0.5) {
                
                //                    self.isVolume = YES;
                //                }else { // 状态改为显示亮度调节
                
                //                    self.isVolume = NO;
                
                /** 显示亮度指示器 */
                [self showBrightnessIndicator];
                //                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged: { // 正在移动
            
            switch (self.panDirection) {
                case FJPanDirectionHorizontal: {
                    
                    // 移动中一直显示快进label
                    self.horizontalLabel.hidden = NO;
                    [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                    
                    break;
                }
                case FJPanDirectionVertical: {
                    
                    //                    if (self.isVolume) {
                    
                    //
                    //                        volume -= veloctyPoint.y / 10000;
                    //
                    //                        self.volumeViewSlider.value -= veloctyPoint.y / 10000;
                    //
                    //                        [[MPMusicPlayerController applicationMusicPlayer] setVolume:volume];
                    
                    //                    }else {
                    // 改变亮度
                    [UIScreen mainScreen].brightness -= veloctyPoint.y / 10000;
                    self.BrightnessProgress.progress -= veloctyPoint.y / 10000;
                    //                    }
                    
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded: { // 移动停止
            
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
                case FJPanDirectionHorizontal: {
                    // 隐藏视图
                    self.horizontalLabel.hidden = YES;
                    
                    //                    /** 开始加载 */
                    [self startLoading];
                    
                    __WEAK_SELF_FJ_VIDEO_PLAYER
                    [self seekToTime:self.sumTime completionHandler:^(BOOL finished) {
                        self.didSeekPlayTime = NO;
                    }];
                    
                    // 把sumTime滞空，不然会越加越多
                    self.sumTime = 0;
                    
                    break;
                }
                case FJPanDirectionVertical: {
                    
                    // 垂直移动结束后，把状态改为不再控制音量
                    self.horizontalLabel.hidden = YES;
                    
                    //                    if (!self.isVolume) {
                    
                    /** 隐藏亮度指示器 */
                    [self hideBrightnessIndicator];
                    //                    }
                    
                    // 垂直移动结束后，把状态改为不再控制音量
                    //                    self.isVolume = NO;
                    break;
                }
                default:
                    break;
            }
            
            /** 滑动结束自动隐藏控制条 */
            [self autoFadeOutControlBar];
            
            break;
        }
        default:
            break;
    }
}

#pragma mark 水平移动显示 快进/快退时间

- (void)horizontalMoved:(CGFloat)value {
    
    // 快进快退的方法
    NSString *style = @"";
    if (value < 0) style = @"<<";
    if (value > 0) style = @">>";
    if (value == 0) return;
    
    // 每次滑动需要叠加时间
    self.sumTime += value / 200;
    
    // 需要限定sumTime的范围
    CMTime totalTime = self.playerItem.duration;
    CGFloat totalMovieDuration = (CGFloat)totalTime.value / totalTime.timescale;
    
    if (self.sumTime > totalMovieDuration) self.sumTime = totalMovieDuration;
    
    if (self.sumTime < 0) self.sumTime = 0;
    
    // 当前快进的时间
    NSString *nowTime = [self durationStringWithTime:(int)self.sumTime];
    // 总时间
    NSString *durationTime = [self durationStringWithTime:(int)totalMovieDuration];
    
    // 更新快进label的时长
    self.horizontalLabel.text = [NSString stringWithFormat:@"%@ %@ / %@",style, nowTime, durationTime];
    
    // 更新slider的进度
    self.controlBar.slider.value = self.sumTime / totalMovieDuration;
    
    // 更新现在播放的时间
    self.controlBar.currentTimeLabel.text = nowTime;
}

#pragma mark 根据时长获取时间格式
/**
 *  根据时长求出字符串
 *
 *  @param time 时长
 *
 *  @return 时长字符串
 */
- (NSString *)durationStringWithTime:(int)time {
    
    // 获取分钟
    NSString *min = [NSString stringWithFormat:@"%02d",time / 60];
    // 获取秒数
    NSString *sec = [NSString stringWithFormat:@"%02d",time % 60];
    
    return [NSString stringWithFormat:@"%@:%@", min, sec];
}

#pragma mark -
#pragma mark >>>>>>>>>> 控制条 通知代理回调 <<<<<<<<<<
#pragma mark -

#pragma mark KVO代理事件 监听 --> 播放状态 / 缓冲状态

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        
        if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            
            //            self.controlBar.playBtn.enabled = YES;
            
            // 加载完成后，再添加平移手势
            // 添加平移手势，用来控制音量、亮度、快进快退
            if (!self.pan && self.enableGesture) {
                self.pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
                self.pan.delegate = self;
                self.pan.delaysTouchesBegan = YES;
                [self addGestureRecognizer:self.pan];
            }
            
            /** 隐藏加载失败 */
            self.horizontalLabel.hidden = YES;
            
            __WEAK_SELF_FJ_VIDEO_PLAYER
            if (self.seekTime > 0) {
                [self seekToTime:self.seekTime completionHandler:^(BOOL finished) {
                    weakSelf.seekTime = 0;
                }];
            }
            
            /** 这一步是防止弱网未加载出封面图的情况下视频播放出来了，当暂停的时候中心应该是正常的暂停图片 */
            UIImageView *centerPlayBackgroud = (UIImageView *)[self.centerPlayBtn viewWithTag:100];
            if (centerPlayBackgroud) {
                centerPlayBackgroud.image = [UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_play_center")];
            }
            self.centerPlayBtn.backgroundColor = [UIColor clearColor];
            
        } else if (self.player.currentItem.status == AVPlayerItemStatusFailed) {
            
            /** 本地视频加载失败，说明文件不完整，删掉本地文件 */
            if (self.isLocalVideo) [[NSFileManager defaultManager] removeItemAtPath:self.videoURL error:nil];
            _horizontalLabel.backgroundColor = [UIColor clearColor];
            self.state = FJPlayerStateFailed;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        
        // 计算缓冲进度
        NSTimeInterval timeInterval = [self availableDuration];
        CMTime duration             = self.playerItem.duration;
        CGFloat totalDuration       = CMTimeGetSeconds(duration);
        
        /** 设置缓冲进度 */
        [self.controlBar.progressView setProgress:timeInterval / totalDuration animated:NO];
        
        // 如果缓冲和当前slider的差值超过0.1,自动播放，解决弱网情况下不会自动播放问题
        if (!self.isPauseByUser && // 不是用户暂停
            !self.didEnterBackground && // 没有进入后台
            ((self.controlBar.progressView.progress - self.controlBar.slider.value) > 0.5)) { // 已经缓冲
            [self play];
        }
        
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        
        // 缓冲为空，加载几秒
        [self bufferingSomeSecond];
        
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        // 缓冲好，挂起
        //        if (self.state == FJPlayerStateBuffering){
        //            self.state = FJPlayerStatePlaying;
        //        }
    }
}

#pragma mark 视频播放完毕通知

- (void)moviePlayDidEnd:(NSNotification *)notification {
    
    self.state = FJPlayerStateStopped;
    
    self.playDidEnd = YES;
    
    // 播放完成回调
    if (self.finishedBlock) {
        self.finishedBlock();
    }
    
    // 初始化显示controlView为YES
    self.isControlBarShowing = YES;
    
    // 延迟隐藏controlBar
    [self animateHideControlBar];
    
    /** 播放结束后显示导航条 */
    self.naviStatusBar.alpha = 1.0;
    
    /** 如果是循环播放 */
    if (self.loopPlay) {
        
        // 准备显示控制层
        self.isControlBarShowing = NO;
        
        [self animateShowControlBar];
        
        // 重置控制层View
        [self.controlBar resetControlView];
        
        self.isFirstPlay = YES;
        
        /** 跳转到0秒开始播放 */
        [self seekToTime:0 completionHandler:nil];
        
        // 没有播放完
        self.playDidEnd = NO;
        
    }else {
        self.playAginBtn.hidden = NO;
        self.centerPauseBtn.hidden = YES;
        self.coverImageView.hidden = NO;
        self.controlBar.playBtn.selected = NO;
    }
    
    /** 如果是全屏，回到小屏 */
    if (self.controlBar.fullScreenBtn.selected) {
        [self hideShareView];
        [self fullScreenClick:self.controlBar.fullScreenBtn];
    }
}

#pragma mark 耳机插拔监听

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // 耳机插入
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            
            // 耳机拔掉，拔掉耳机继续播放
            [self play];
            
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            //            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    /** ① 控制条不响应pan手势， ② 导航不响应pan手势 */
    if ( [touch.view isDescendantOfView:self.controlBar] || [touch.view isDescendantOfView:self.naviStatusBar] ) //|| [touch.view isDescendantOfView:self.shareView]
        return NO;
    
    return YES;
}

#pragma mark 自动隐藏控制条

- (void)autoFadeOutControlBar {
    
    if (!self.isControlBarShowing) return;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animateHideControlBar) object:nil];
    
    [self performSelector:@selector(animateHideControlBar) withObject:nil afterDelay:FJ_AUTO_FATE_CONTROL_BAR_TIMEINTERVAL];
}

#pragma mark 取消自动隐藏控制条

- (void)cancelAutoFadeOutControlBar {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark 隐藏控制条

- (void)animateHideControlBar {
    
    if (!self.isControlBarShowing) return;
    
    [UIView animateWithDuration:FJ_CONTROL_BAR_ANIMATION_TIMEINTERVAL animations:^{
        
        self.controlBar.alpha = 0;
        if (self.controlBar.fullScreenBtn.selected && !self.playDidEnd) {
            self.naviStatusBar.alpha = 0;
        }
        //隐藏控制条回调
        if (self.controlBarHideBlock) {
            self.controlBarHideBlock(YES);
        }
    }completion:^(BOOL finished) {
        
        self.isControlBarShowing = NO;
    }];
}

#pragma mark 显示控制条

- (void)animateShowControlBar {
    
    if (self.isControlBarShowing) return;
    
    [UIView animateWithDuration:FJ_CONTROL_BAR_ANIMATION_TIMEINTERVAL animations:^{
        
        self.controlBar.alpha = 1.0;
        if (self.controlBar.fullScreenBtn.selected) {
            self.naviStatusBar.alpha = 1.0;
        }
        //隐藏控制条回调
        if (self.controlBarHideBlock) {
            self.controlBarHideBlock(NO);
        }
    } completion:^(BOOL finished) {
        
        self.isControlBarShowing = YES;
        
        /** 当暂停时不自动隐藏控制条 */
        if (self.controlBar.playBtn.selected) {
            [self autoFadeOutControlBar];
        }
    }];
}

#pragma mark 显示亮度指示器

- (void)showBrightnessIndicator {
    
    [UIView animateWithDuration:FJ_CONTROL_BAR_ANIMATION_TIMEINTERVAL animations:^{
        
        self.BrightnessProgress.alpha = 1.0;
        self.brightnessIconView.alpha = 1.0;
        
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark 隐藏亮度指示器

- (void)hideBrightnessIndicator {
    
    [UIView animateWithDuration:FJ_CONTROL_BAR_ANIMATION_TIMEINTERVAL animations:^{
        
        self.BrightnessProgress.alpha = 0.0;
        self.brightnessIconView.alpha = 0.0;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark 显示分享

- (void)showShareView {
    //    [self pause];
    [UIView animateWithDuration:FJ_CONTROL_BAR_ANIMATION_TIMEINTERVAL animations:^{
//        self.shareView.alpha = 1.0;
    }];
}

#pragma mark 隐藏分享

- (void)hideShareView {
    [self play];
    [UIView animateWithDuration:FJ_CONTROL_BAR_ANIMATION_TIMEINTERVAL animations:^{
//        self.shareView.alpha = 0.0;
    }];
}

#pragma mark 显示加载动画

- (void)startLoading {
    if (self.isLocalVideo) return;
    self.showCenterPlayBtn = NO;
    self.loadingImageView.hidden = NO;
}

#pragma mark 隐藏加载动画

- (void)stopLoading {
    _loadingImageView.hidden = YES;
}

#pragma mark APP退到后台

- (void)appDidEnterBackground {
    
    self.didEnterBackground = YES;
    
    if (self.state == FJPlayerStatePause) return;
    
    if (self.state == FJPlayerStatePlaying) {
        [_player pause];
        self.state = FJPlayerStatePause;
        [self cancelAutoFadeOutControlBar];
        self.controlBar.playBtn.selected = NO;
    }
}

#pragma mark APP回到前台

- (void)appDidEnterForeGround {
    
    self.didEnterBackground = NO;
    
    if (self.state != FJPlayerStatePause) return;
    
    self.isControlBarShowing = NO;
    
    // 延迟隐藏controlBar
    [self animateShowControlBar];
    
    if (!self.isPauseByUser) {
        
        [self play];
    }
}

#pragma mark -
#pragma mark >>>>>>>>>> setter / getter / dealloc <<<<<<<<<<
#pragma mark -

#pragma mark playerItem的setter方法 --> 移除 / 添加 KVO 监听

- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (_playerItem == playerItem) return;
    
    /** 已有item，则先移除对item的KVO */
    if (_playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    
    _playerItem = playerItem;
    
    /** 对新的item添加KVO监听 */
    if (playerItem) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    }
}

#pragma mark videoURL的setter方法，非法URL判断，是否有本地缓存判断等

- (void)setVideoURL:(NSString *)videoURL {
    
    _videoURL = [videoURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (videoURL.length && [videoURL isKindOfClass:[NSString class]]) {
        [[FJVideoCacheManager sharedManager] videoExistWithNetUrl:_videoURL completion:^(NSString * __nullable localPath) {
            if (localPath.length) {
                NSURL *fileUrl = [NSURL fileURLWithPath:localPath];
                if (fileUrl) {
                    _videoURL = fileUrl.absoluteString;
                }
            }
        }];
    }
    
    // 每次加载视频URL都设置重播为NO
    self.playDidEnd   = NO;
    
    self.isPauseByUser = YES;
}

#pragma mark state播放状态setter

- (void)setState:(FJPlayerState)state {
    
    _state = state;
    
    switch (state) {
        case FJPlayerStateFailed: {
            if (self.loadFailedBlock) self.loadFailedBlock();
            
            [self stopLoading];
            
            /** 独特需求：详情页的视频加载失败时显示提示；首页的视频加载失败显示播放按钮和封面 */
            if (self.isNotCellVideo) {
                self.horizontalLabel.hidden = NO;
                self.horizontalLabel.text = @"加载失败，点击重试";
                self.showCenterPlayBtn = NO;
            }else {
                self.showCenterPlayBtn = YES;
            }
            break;
        }
        case FJPlayerStateBuffering: {
            
            if (self.isLocalVideo) return;
            
            /** 判断是否播放结束：避免循环播放时每次从头播放闪现加载动画 */
            if (!self.playDidEnd && !self.pausedBeforeReady) [self startLoading];
            if (!self.isNotCellVideo || self.didSeekPlayTime) {
                [self startLoading];
            }
            
            break;
        }
        case FJPlayerStatePlaying: {
            if (self.controlBar.playBtn.selected == YES) {
                self.showCenterPlayBtn = NO;
            }
            [self stopLoading];
            self.controlBar.slider.userInteractionEnabled = YES;
            break;
        }
        case FJPlayerStateStopped: {
            break;
        }
        case FJPlayerStatePause: {
            /** 滑动期间不显示中间的播放按钮 */
            if (!self.didSeekPlayTime) {
                self.showCenterPlayBtn = !self.controlBar.playBtn.selected;
            }
            [self stopLoading];
            break;
        }
    }
}

- (void)setEnableGesture:(BOOL)enableGesture {
    _enableGesture = enableGesture;
    if (!enableGesture) {
        [self removeGestureRecognizer:self.pan];
        self.pan.delegate = nil;
        self.pan = nil;
    }else {
        if (!self.pan) {
            self.pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
            self.pan.delegate = self;
            self.pan.delaysTouchesBegan = YES;
            [self addGestureRecognizer:self.pan];
        }
    }
}

- (void)setDidSeekPlayTime:(BOOL)didSeekPlayTime {
    _didSeekPlayTime = didSeekPlayTime;
    if (didSeekPlayTime) {
        self.showCenterPlayBtn = NO;
    }else {
        self.showCenterPlayBtn = !self.controlBar.playBtn.selected;
    }
}

- (void)setShowControlBar:(BOOL)showControlBar {
    _showControlBar = showControlBar;
    if (!showControlBar) {
        [self.naviStatusBar removeFromSuperview];
        self.controlBar.hidden = YES;
    }else{
        self.controlBar.hidden = NO;
    }
}

- (void)setMute:(BOOL)mute {
    _mute = mute;
    if (_player) {
        _player.muted = mute;
    }
}

- (void)setVideoTitle:(NSString *)videoTitle {
    _videoTitle = videoTitle;
    self.naviStatusBar.titleLabel.text = videoTitle;
}

- (void)setCoverImage:(UIImage *)coverImage {
    _coverImage = coverImage;
    if (coverImage) {
        self.coverImageView.image = coverImage;
        UIImageView *centerPlayBackgroud = (UIImageView *)[self.centerPlayBtn viewWithTag:100];
        if (centerPlayBackgroud)
        {
            centerPlayBackgroud.image = [UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_play_center")];
        }
        self.centerPlayBtn.backgroundColor = [UIColor clearColor];
    }
}

- (void)setIsNotCellVideo:(BOOL)isNotCellVideo {
    _isNotCellVideo = isNotCellVideo;
    self.backgroundColor = isNotCellVideo ? [UIColor colorWithWhite:0.133 alpha:1.000] : [UIColor colorWithRed:0.898 green:0.902 blue:0.910 alpha:1.000];
    if (isNotCellVideo) {
        self.showCenterPlayBtn = NO;
        self.volumView.hidden = NO;
    }else {
        self.showCenterPlayBtn = YES;
        self.volumView.hidden = YES;
    }
}

-(void)setShowNavBar:(BOOL)showNavBar
{
    _showNavBar = showNavBar;
    if (!showNavBar)
    {
        [self.naviStatusBar removeFromSuperview];
    }
    else
    {
        [self addSubview:self.naviStatusBar];
        [self.naviStatusBar mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.mas_equalTo(0);
            make.height.mas_equalTo(45.f);
        }];
    }
}

-(void)setTotalTime:(NSString *)totalTime {
    _totalTime = totalTime;
    // 初始当前播放时间00:00
    self.controlBar.currentTimeLabel.text = [NSString stringWithFormat:@"00:00"];
    // 初始总时间，外部传入的时间
    totalTime = totalTime.length > 0 ? totalTime :@"00:00";
    self.controlBar.totalTimeLabel.text   = [NSString stringWithFormat:@"%@", totalTime];
}

- (void)setShowCenterPlayBtn:(bool)showCenterPlayBtn {
    _showCenterPlayBtn = showCenterPlayBtn;
    if (showCenterPlayBtn) {
        self.centerPlayBtn.hidden = NO;
        self.centerPauseBtn.hidden = YES;
    }else {
        self.centerPlayBtn.hidden = YES;
        self.centerPauseBtn.hidden = NO;
    }
}

-(NSInteger)currentTime
{
    NSInteger currentTime = (NSInteger)round(CMTimeGetSeconds([self.playerItem currentTime]));
    return currentTime;
}

- (UILabel *)horizontalLabel {
    
    if (!_horizontalLabel) {
        _horizontalLabel                 = [[UILabel alloc] init];
        _horizontalLabel.textColor       = [UIColor whiteColor];
        _horizontalLabel.textAlignment   = NSTextAlignmentCenter;
        _horizontalLabel.font            = _FONTDBMRegular(14.f);
        _horizontalLabel.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_mask_background")]];
        _horizontalLabel.hidden = YES;
        _horizontalLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _horizontalLabel;
}

- (UIProgressView *)BrightnessProgress {
    if (!_BrightnessProgress) {
        _BrightnessProgress = [[UIProgressView alloc] init];
        _BrightnessProgress.transform = CGAffineTransformMakeRotation(-M_PI_2);
        _BrightnessProgress.progressTintColor = [UIColor colorWithRed:0.0841 green:0.5137 blue:0.9985 alpha:1.0];
        _BrightnessProgress.trackTintColor = [UIColor whiteColor];
        _BrightnessProgress.progress = [UIScreen mainScreen].brightness;
        _BrightnessProgress.alpha = 0;
    }
    return _BrightnessProgress;
}

- (UIImageView *)brightnessIconView {
    if (!_brightnessIconView) {
        _brightnessIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_brightness")]];
        _brightnessIconView.alpha = 0;
    }
    return _brightnessIconView;
}

//- (FJVideoShareView *)shareView {
//    if (!_shareView) {
//        _shareView = [FJVideoShareView new];
//        _shareView.alpha = 0.0;
//        __WEAK_SELF_FJ_VIDEO_PLAYER
//        _shareView.shareBtnClickBlock = ^(FJVideoShareBtnType btnType){
//            [weakSelf hideShareView];
//            if (weakSelf.shareBtnClickBlock) {
//                weakSelf.shareBtnClickBlock(btnType);
//            }
//        };
//        [_shareView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideShareView)]];
//    }
//    return _shareView;
//}

- (UIImageView *)loadingImageView {
    if (!_loadingImageView) {
        _loadingImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_loading")]];
        _loadingImageView.backgroundColor = [UIColor clearColor];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation.toValue = [NSNumber numberWithFloat:M_PI * 2.0];
        animation.duration = 2;
        animation.removedOnCompletion = NO;
        animation.repeatCount = MAXFLOAT;
        [self.loadingImageView.layer addAnimation:animation forKey:@"rotationAnimation"];
        _loadingImageView.hidden = YES;
    }
    return _loadingImageView;
}

#pragma mark 重置player

- (void)destroyPlayer {
    
    // 改为为播放完
    self.playDidEnd         = NO;
    
    self.didEnterBackground = NO;
    
    if (self.timeObserve) {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve    = nil;
    }
    
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // 暂停
    [self pause];
    
    /** 播放属性置空 */
    [self.playerLayer removeFromSuperlayer];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.urlAsset       = nil;
    self.playerItem     = nil;
    self.player         = nil;
    self.playerLayer    = nil;
    
    /** 手势置空 */
    self.tap            = nil;
    self.pan            = nil;
    
    /** UI更新 */
    [self stopLoading];
    self.horizontalLabel.hidden = YES;
    [self.controlBar resetControlView];
    
    /** 修改播放状态 */
    self.state = FJPlayerStateStopped;
    
    /** 取消缓存下载 */
    [[FJVideoCacheManager sharedManager] cancelDownloadTaskWithURL:self.videoURL];
}

#pragma mark 更新playerLayer的frame

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _playerLayer.frame = self.bounds;
}

- (void)dealloc {
    
    self.playerItem = nil;
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // 移除time观察者
    if (self.timeObserve) {
        
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
    //    NSLog(@"%s", __FUNCTION__);
}




@end







