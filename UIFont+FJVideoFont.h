//
//  UIFont+FJVideoFont.h
//  FJVideo
//
//  Created by wangfj on 2017/8/21.
//  Copyright © 2017年 FJVideo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFont (FJVideoFont)
//细体
+ (UIFont *)dbmFontOfLight:(CGFloat)fontSize weight:(CGFloat)weight;
//常规
+ (UIFont *)dbmFontOfRegular:(CGFloat)fontSize weight:(CGFloat)weight;
//粗体
+ (UIFont *)dbmFontOfBold:(CGFloat)fontSize weight:(CGFloat)weight;

@end
