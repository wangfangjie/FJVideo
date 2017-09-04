//
//  FJVideoControlBar.m
//  FJVideo
//
//  Created by wangfj on 2017/8/21.
//  Copyright © 2017年 FJVideo. All rights reserved.
//

#import "FJVideoControlBar.h"
#import <Masonry.h>
@implementation FJVideoControlBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        /** 取消自动转换AutoresizingMask为约束 */
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3];
        
        /** 播放按钮 */
        UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _playBtn = playBtn;
        [playBtn setImage:[UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_play")] forState:UIControlStateNormal];
        [playBtn setImage:[UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_pause")] forState:UIControlStateSelected];
        playBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, FJ_TIME_LABEL_WIDTH);
        [self addSubview:playBtn];
        
        /** 当前时间 */
        UILabel *currentTimeLabel = [UILabel new];
        _currentTimeLabel = currentTimeLabel;
        currentTimeLabel.font = _FONTDBMBold(10.f);
        currentTimeLabel.textAlignment = NSTextAlignmentCenter;
        currentTimeLabel.textColor = [UIColor whiteColor];
        [self addSubview:currentTimeLabel];
        
        /** 缓冲进度条 */
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView = progressView;
        progressView.progressTintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
        progressView.trackTintColor    = [UIColor clearColor];
        [self addSubview:progressView];
        
        /** 滑块 */
        UISlider *slider = [[UISlider alloc] init];
        _slider = slider;
        [slider setThumbImage:[UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_slider")] forState:UIControlStateNormal];
        slider.maximumValue = 1;
        slider.minimumTrackTintColor = [UIColor colorWithRed:0.0841 green:0.5137 blue:0.9985 alpha:1.0];
        slider.maximumTrackTintColor = [UIColor colorWithRed:0.572 green:0.5592 blue:0.5595 alpha:0.5];
        [self addSubview:slider];
        
        /** 总时间 */
        UILabel *totalTimeLabel = [UILabel new];
        _totalTimeLabel = totalTimeLabel;
        totalTimeLabel.font = _FONTDBMBold(10.f);;
        totalTimeLabel.textAlignment = NSTextAlignmentCenter;
        totalTimeLabel.textColor = [UIColor whiteColor];
        [self addSubview:totalTimeLabel];
        
        /** 全屏按钮 */
        UIButton *fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _fullScreenBtn = fullScreenBtn;
        [fullScreenBtn setImage:[UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_fullscreen")] forState:UIControlStateNormal];
        [fullScreenBtn setImage:[UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_shrink_screen")] forState:UIControlStateSelected];
        fullScreenBtn.imageEdgeInsets = UIEdgeInsetsMake(0, FJ_TIME_LABEL_WIDTH, 0, 0);
        [self addSubview:fullScreenBtn];
        
        /** 将播放和全屏放到最前面 */
        [self bringSubviewToFront:playBtn];
        [self bringSubviewToFront:fullScreenBtn];
        
        // 添加约束
        [playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(FJ_PLAY_FULL_BTN_WIDTH + FJ_TIME_LABEL_WIDTH);
            make.left.mas_equalTo(0);
            make.centerY.mas_equalTo(self);
        }];
        
        [currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(playBtn);
            make.left.mas_equalTo(FJ_PLAY_FULL_BTN_WIDTH);
            make.width.mas_equalTo(FJ_TIME_LABEL_WIDTH);
        }];
        
        [fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self);
            make.centerY.mas_equalTo(playBtn);
            make.size.mas_equalTo(playBtn);
        }];
        
        [self.totalTimeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(-FJ_PLAY_FULL_BTN_WIDTH);
            make.centerY.equalTo(self.playBtn);
            make.width.mas_equalTo(FJ_TIME_LABEL_WIDTH);
        }];
        
        [self.slider mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.currentTimeLabel.mas_right).offset(5.f);
            make.centerY.mas_equalTo(self.playBtn);
            make.right.mas_equalTo(self.totalTimeLabel.mas_left).offset(-5.f);
        }];
        
        [self.progressView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.width.mas_equalTo(self.slider);
            make.centerY.mas_equalTo(self.slider.mas_centerY).offset(1);
        }];
        
        // 添加点击手势
        UITapGestureRecognizer *sliderTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSliderAction:)];
        [slider addGestureRecognizer:sliderTap];
        
        // 重置控制条
        [self resetControlView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _currentTimeLabel.preferredMaxLayoutWidth = FJ_TIME_LABEL_WIDTH;
    _totalTimeLabel.preferredMaxLayoutWidth = FJ_TIME_LABEL_WIDTH;
}

#pragma mark - slider点击手势事件

- (void)tapSliderAction:(UITapGestureRecognizer *)tap {
    
    // 当手势父视图是slider(防止因其他手势导致自带滑动失效)，且回调有值
    if ([tap.view isKindOfClass:[UISlider class]] && self.tapBlock) {
        UISlider *slider = (UISlider *)tap.view;
        CGPoint point    = [tap locationInView:slider];
        CGFloat length   = slider.frame.size.width;
        // 视频跳转的value
        CGFloat tapValue = point.x / length;
        self.slider.value = tapValue;
        self.tapBlock(tapValue);
    }
}

#pragma mark 重置控制条

- (void)resetControlView {
    self.slider.value          = 0;
    self.progressView.progress = 0;
    self.currentTimeLabel.text = @"--:--";
    self.totalTimeLabel.text   = @"--:--";
}

@end


@implementation FJVideoProgressView

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        /** 缓冲进度条 */
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView = progressView;
        progressView.progressTintColor = [UIColor whiteColor];
        progressView.trackTintColor    = [UIColor clearColor];
        [self addSubview:progressView];
        [progressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(self);
        }];
        
        /** 滑块 */
        UISlider *slider = [[UISlider alloc] init];
        _slider = slider;
        slider.maximumValue = 1;
        slider.minimumTrackTintColor = [UIColor colorWithRed:0.0841 green:0.5137 blue:0.9985 alpha:1.0];
        slider.maximumTrackTintColor = [UIColor colorWithRed:0.572 green:0.5592 blue:0.5595 alpha:0.5];
        UIImage *image = [self OriginImage:[UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_slider")] scaleToSize:CGSizeMake(1, 1)];
        [slider setThumbImage:image forState:UIControlStateNormal];
        
        [self addSubview:slider];
        [slider mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(self);
        }];
    }
    return self;
}

-(UIImage *)OriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0, size.width, size.height)];
    UIImage *scaleImage=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaleImage;
}

@end















