//
//  FJVideoNaviBar.h
//  FJVideo
//
//  Created by wangfj on 2017/8/22.
//  Copyright © 2017年 FJVideo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FJVideoNaviBar : UIView

/** 返回按钮 */
@property (nonatomic, weak, readonly) UIButton *backBtn;
/** 标题Label */
@property (nonatomic, weak, readonly) UILabel  *titleLabel;
/** 背景view */
@property (nonatomic, weak, readonly) UIView   *naviBackgoundView;
/** 分享按钮 */
@property (nonatomic, weak, readonly) UIButton *shareBtn;
/** 当前是否是全屏 */
@property (nonatomic, assign, getter=isFullScreen) BOOL fullScreen;


@end
