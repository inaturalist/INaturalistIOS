//
//  UIColor+INaturalist.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/13/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "UIColor+INaturalist.h"

@implementation UIColor (INaturalist)
+ (UIColor *)inatTint
{
    return [UIColor colorWithRed:114.0/255.0 green:173.0/255.0 blue:34.0/255.0 alpha:1];
}

+ (UIColor *)inatDarkGreen {
    return [UIColor colorWithHexString:@"#588039"];
}
@end
