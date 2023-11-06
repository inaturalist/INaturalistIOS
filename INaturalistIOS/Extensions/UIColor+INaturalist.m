//
//  UIColor+INaturalist.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/13/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

@import UIColor_HTMLColors;

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

+ (UIColor *)inatTableViewBackgroundGray {
    return [UIColor colorWithHexString:@"#EFEFF4"];
}

+ (UIColor *)inatGray {
    return [UIColor colorWithHexString:@"#95a5a6"];
}

+ (UIColor *)inatBlack {
    return [UIColor colorWithHexString:@"#34495e"];
}

+ (UIColor *)inatRed {
    return [UIColor colorWithHexString:@"#e74c3c"];
}

// explore ui custom colors
+ (UIColor *)colorForResearchGradeNotice {
    return [UIColor colorWithHexString:@"#529214"];
}

+ (UIColor *)secondaryColorForResearchGradeNotice {
    return [UIColor colorWithHexString:@"#dceea3"];
}

+ (UIColor *)mapOverlayColor {
    return [UIColor colorWithHexString:@"#daa520"];
}

// color tweak helper
- (UIColor *)darkerColor
{
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b * 0.4
                               alpha:a];
    return nil;
}

// iconic taxa
+ (UIColor *)colorForIconicTaxon:(NSString *)iconicTaxon {

    if ([iconicTaxon isEqualToString:@"Fungi"])
        return [UIColor colorWithHexString:@"#ff0066"];

    else if ([iconicTaxon isEqualToString:@"Plantae"])
        return [UIColor colorWithHexString:@"#73ac13"];

    else if ([iconicTaxon isEqualToString:@"Animalia"])
        return [UIColor colorWithHexString:@"#1e90ff"];

    else if ([iconicTaxon isEqualToString:@"Mollusca"])
        return [UIColor colorWithHexString:@"#ff4500"];

    else if ([iconicTaxon isEqualToString:@"Aves"])
        return [UIColor colorWithHexString:@"#1e90ff"];

    else if ([iconicTaxon isEqualToString:@"Amphibia"])
        return [UIColor colorWithHexString:@"#1e90ff"];

    else if ([iconicTaxon isEqualToString:@"Reptilia"])
        return [UIColor colorWithHexString:@"#1e90ff"];

    else if ([iconicTaxon isEqualToString:@"Mammalia"])
        return [UIColor colorWithHexString:@"#1e90ff"];

    else if ([iconicTaxon isEqualToString:@"Actinopterygii"])       // ray-finned fishes
        return [UIColor colorWithHexString:@"#1e90ff"];

    else if ([iconicTaxon isEqualToString:@"Arachnida"])
        return [UIColor colorWithHexString:@"#ff4500"];

    else if ([iconicTaxon isEqualToString:@"Insecta"])
        return [UIColor colorWithHexString:@"#ff4500"];

    else if ([iconicTaxon isEqualToString:@"Chromista"])
        return [UIColor colorWithHexString:@"#993300"];

    else if ([iconicTaxon isEqualToString:@"Protozoa"])
        return [UIColor colorWithHexString:@"#691776"];

    else
        return [UIColor colorWithHexString:@"#1e90ff"];             // default
}


@end
