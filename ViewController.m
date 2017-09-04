//
//  ViewController.m
//  FJVideo
//
//  Created by wangfj on 2017/8/21.
//  Copyright © 2017年 FJVideo. All rights reserved.
//

#import "ViewController.h"
#import "FJVideoPlayer.h"
#import <Masonry.h>

@interface ViewController ()
@property (nonatomic, strong) FJVideoPlayer  *playerView;//播放器
@property (nonatomic, strong) UIView         *frameView;
@property (nonatomic, strong) UIView    *topView;//标题带阴影
@property (nonatomic, strong) UILabel   *titleLbl;//上部的标题

@end

#define _var_weakSelf    __weak __typeof(self) weakSelf = self;
#define __NC              [NSNotificationCenter defaultCenter]

#define _NC_Send(__n, __o)   [__NC postNotificationName:__n object:__o]
#define _NC_Add(__ob, __sel, __n, __o)      [__NC addObserver:__ob selector:__sel name:__n object:__o]

#define kWidth_Screen               CGRectGetWidth([UIScreen mainScreen].bounds)

#define ScreenWidth         kWidth_Screen


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createVideoPlayer];
    self.playerView.videoURL = @"http://v2.xinstatic.com/2017/0823/KDB6CIL4JAYDPH1ZRWYNRWCUNWQAJGLK.f0.mp4?f0_md5=bbc3cd1cdf38a1206f9191f91e66433e";
    [self.playerView autoPlayVideo];
    [self.playerView play];
    self.playerView.videoTitle =@"你好";
    self.playerView.totalTime  = @"12:00";

    _NC_Add(self, @selector(pageContollerScrollNotif:), @"VIDEO_SLIDER_NOTIFICATION", nil);
}
- (void)pageContollerScrollNotif:(NSNotification *)notif
{
    NSDictionary *obj = (NSDictionary *)notif.object;
    BOOL scrollEnable = [obj objectForKey:@"scrollEnable"];
//    self.pageController.scrollEnable = YES;
}

- (void)createVideoPlayer;
{
    //**************以下是视频播放界面********************
    
    if (!self.playerView)
    {
        FJVideoPlayer *playerView = [[FJVideoPlayer alloc] init];
        _playerView = playerView;
        playerView.showNavBar = NO;
        playerView.enableGesture = YES;
        playerView.isNotCellVideo = YES;
        playerView.showCenterPlayBtn = YES;
        playerView.userInteractionEnabled = YES;
        [self.view addSubview:playerView];
        [self.playerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(self.view);
        }];
        _var_weakSelf;
        playerView.finishedBlock = ^(void){
//            [weakSelf sendVideoPlay];
        };
        //标题随视频控制栏的隐藏而隐藏
        playerView.controlBarHideBlock = ^(BOOL isHide){
            if (isHide) {
                [weakSelf hideTopView];
            }else {
                [weakSelf showTopView];
            }
        };
//        playerView.playBtnClickedBlock = ^(){
//           [self.playerView autoPlayVideo];
//        };
        //发送通知，控制pageController是否滑动，防止滑动冲突
        playerView.sliderTapBlock = ^(CGFloat value){
//            _NC_Send(@"VIDEO_SLIDER_NOTIFICATION", @{@"scrollEnable":@(0)});
            
        };
        playerView.sliderEndBlock = ^(void){
            _NC_Send(@"VIDEO_SLIDER_NOTIFICATION", @{@"scrollEnable":@(1)});
        };
        [self createFrameView];

//        [self crateTopView];
    }
}

- (void)hideTopView;
{
    if (self.topView && self.topView.alpha > .95) {
        self.topView.alpha = 0.f;
    }
}

- (void)showTopView;
{
    if (self.topView && self.topView.alpha < .05) {
        self.topView.alpha = 1.f;
    }
}
- (void)crateTopView;
{
    if (self.topView)
    {
        [self.topView removeFromSuperview];
        self.topView = nil;
    }
    
    {
        self.topView = [UIView new];
        [self.view addSubview:self.topView];
        self.topView.userInteractionEnabled = YES;
//        [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(jumpToDetail)]];
        self.topView.backgroundColor = [UIColor clearColor];
        [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.mas_equalTo(0);
            make.height.mas_equalTo(70);
        }];
        
        //  添加渐变层
        CAGradientLayer * shadow = [CAGradientLayer layer];
        [self.topView.layer addSublayer:shadow];
        shadow.frame = CGRectMake(0, 0,ScreenWidth,70);
        //  设置渐变的方向
        shadow.startPoint = CGPointMake(0, 0);
        shadow.endPoint = CGPointMake(0, 1);
        UIColor *c1 = [[UIColor blackColor] colorWithAlphaComponent:.8];
        UIColor *c2 = [[UIColor blackColor] colorWithAlphaComponent:.0];
        //  设置渐变的颜色
        shadow.colors = @[(__bridge id)c1.CGColor,
                          (__bridge id)c2.CGColor];
        //  设置渐变分割点
        shadow.locations = @[@(0.f), @(1.0f)];
        
        
        self.titleLbl = [UILabel new];
        self.titleLbl.font = [UIFont systemFontOfSize:15];
        self.titleLbl.textColor = [UIColor whiteColor];
        self.titleLbl.text = @"";
        self.titleLbl.numberOfLines = 2;
        [self.topView addSubview:self.titleLbl];
        [self.titleLbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.mas_equalTo(15);
            make.right.mas_equalTo(-15);
        }];
        
    }
    
}

- (void)createFrameView//记录video的frame，转屏用
{
    _frameView = [UIView new];
    [self.view addSubview:_frameView];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
