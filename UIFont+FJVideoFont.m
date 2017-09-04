//
//  UIFont+FJVideoFont.m
//  FJVideo
//
//  Created by wangfj on 2017/8/21.
//  Copyright © 2017年 FJVideo. All rights reserved.
//

#import "UIFont+FJVideoFont.h"
#import "FJVideoPublic.h"
@implementation UIFont (FJVideoFont)
//细体
+ (UIFont *)dbmFontOfLight:(CGFloat)fontSize weight:(CGFloat)weight {
    
    if (fontSize == 0) fontSize = 12.;
    
    if (IOS8_2_OR_LATER) {
        return [UIFont systemFontOfSize:fontSize weight:UIFontWeightUltraLight];
    } else {
        return [UIFont systemFontOfSize:fontSize];
    }
}

//常规
+ (UIFont *)dbmFontOfRegular:(CGFloat)fontSize weight:(CGFloat)weight {
    
    if (fontSize == 0) fontSize = 12.;
    
    if (IOS8_2_OR_LATER) {
        return [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular];
    } else {
        return [UIFont systemFontOfSize:fontSize];
    }
}

//粗体
+ (UIFont *)dbmFontOfBold:(CGFloat)fontSize weight:(CGFloat)weight {
    
    if (fontSize == 0) fontSize = 12.;
    
    if (IOS8_2_OR_LATER) {
        return [UIFont systemFontOfSize:fontSize weight:UIFontWeightMedium];
    } else {
        return [UIFont boldSystemFontOfSize:fontSize];
    }
}

@end
