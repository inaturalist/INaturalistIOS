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
    return [UIColor colorWithHexString:@"#74ac00"];
}

+ (UIColor *)inatDarkGreen {
    return [UIColor colorWithHexString:@"#5a7700"];
}

+ (UIColor *)inatInactiveGreyTint {
    return [UIColor colorWithHexString:@"#666666"];
}

+ (UIColor *)inatDarkGray {
    return [UIColor colorWithHexString:@"#5D5D5D"];
}

+ (UIColor *)inatLightGray {
    return [UIColor colorWithHexString:@"#7B7B7B"];
}

@end
