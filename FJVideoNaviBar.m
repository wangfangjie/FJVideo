//
//  FJVideoNaviBar.m
//  FJVideo
//
//  Created by wangfj on 2017/8/22.
//  Copyright © 2017年 FJVideo. All rights reserved.
//

#import "FJVideoNaviBar.h"
#import "FJVideoPublic.h"
#import "Masonry.h"

@implementation FJVideoNaviBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        /** 取消自动转换AutoresizingMask为约束 */
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        /** 背景view */
        UIView *naviBackgoundView = UIView.new;
        _naviBackgoundView = naviBackgoundView;
        [self addSubview:naviBackgoundView];
        
        /** 标题Label */
        UILabel *titleLabel = UILabel.new;
        _titleLabel = titleLabel;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = _FONTDBMRegular(18.f);;
        [self addSubview:titleLabel];
        
        /** 返回按钮 */
        UIButton *backBtn = [UIButton new];
        _backBtn = backBtn;
        [backBtn setImage:[UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_back_full")] forState:UIControlStateNormal];
        backBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 20);
        [self addSubview:backBtn];
        
        /** 分享按钮 */
        UIButton *shareBtn = UIButton.new;
        _shareBtn = shareBtn;
        [shareBtn setImage:[UIImage imageNamed:FJ_BUNDLE_IMAGE_NAME(@"FJVideoPlayer_share")] forState:UIControlStateNormal];
        [self addSubview:shareBtn];
        if (CBLCopyApplication) {
            shareBtn.hidden = YES;
        }
        
        /** 添加约束 */
        [naviBackgoundView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(0);
        }];
        
        [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.mas_leading).offset(-5.f);
            make.top.mas_equalTo(-2.5);
            make.height.mas_equalTo(50);
            /** 20是为了图片右侧多出20点击区域 */
            make.width.mas_equalTo(20 + 50);
        }];
        
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(backBtn.mas_trailing).offset(-24);
            make.centerY.equalTo(backBtn.mas_centerY);
            make.trailing.equalTo(shareBtn.mas_leading).offset(-10);
        }];
        
        [shareBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(50);
            make.trailing.equalTo(naviBackgoundView.mas_trailing).offset(1.5f);
            make.centerY.equalTo(backBtn.mas_centerY);
        }];
        
        /** 默认是小屏幕状态，隐藏标题 */
        titleLabel.hidden = YES;
    }
    return self;
}

/** 全屏setter方法：用于改变标题隐藏和背景颜色 */
- (void)setFullScreen:(BOOL)fullScreen {
    
    _fullScreen = fullScreen;
    
    if (fullScreen) {
        _naviBackgoundView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3];
        
        _titleLabel.hidden = NO;
    }else {
        _naviBackgoundView.backgroundColor = [UIColor clearColor];
        
        _titleLabel.hidden = YES;
    }
}



@end
