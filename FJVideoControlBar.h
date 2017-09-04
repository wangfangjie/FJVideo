//
//  FJVideoControlBar.h
//  FJVideo
//
//  Created by wangfj on 2017/8/21.
//  Copyright © 2017年 FJVideo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FJVideoPublic.h"

@interface FJVideoControlBar : UIView

/** 播放按钮 */
@property (nonatomic, weak, readonly) UIButton       *playBtn;
/** 当前时间Label */
@property (nonatomic, weak, readonly) UILabel        *currentTimeLabel;
/** 进度滑块 */
@property (nonatomic, weak, readonly) UISlider       *slider;
/** 总时间Label */
@property (nonatomic, weak, readonly) UILabel        *totalTimeLabel;
/** 全屏按钮 */
@property (nonatomic, weak, readonly) UIButton       *fullScreenBtn;
/** 缓冲进度 */
@property (nonatomic, weak, readonly) UIProgressView *progressView;
/** slider点击事件回调 */
@property (nonatomic, copy          ) SliderTapBlock tapBlock;

/** 重置控制条，设置为初始值 */
- (void)resetControlView;
@end

@interface FJVideoProgressView : UIView

/** 进度滑块 */
@property (nonatomic, weak, readonly) UISlider       *slider;
/** 缓冲进度 */
@property (nonatomic, weak, readonly) UIProgressView *progressView;

@end










