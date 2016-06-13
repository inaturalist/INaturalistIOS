//
//  UIColor+ExploreColors.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/20/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import "UIColor+ExploreColors.h"

@implementation UIColor (ExploreColors)

+ (UIColor *)inatGreen {
    return [UIColor colorWithHexString:@"#72ad22"];
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

// notices
+ (UIColor *)colorForResearchGradeNotice {
    return [UIColor colorWithHexString:@"#529214"];
}

+ (UIColor *)secondaryColorForResearchGradeNotice {
    return [UIColor colorWithHexString:@"#dceea3"];
}

+ (UIColor *)colorForIdPleaseNotice {
    return [UIColor colorWithHexString:@"#85743d"];
}

+ (UIColor *)secondaryColorForIdPleaseNotice {
    return [UIColor colorWithHexString:@"#ffee91"];
}


// style colors
+ (UIColor *)inatGray {
    return [UIColor colorWithHexString:@"#95a5a6"];
}

+ (UIColor *)inatBlack {
    return [UIColor colorWithHexString:@"#34495e"];
}

+ (UIColor *)inatRed {
    return [UIColor colorWithHexString:@"#e74c3c"];
}

+ (UIColor *)mapOverlayColor {
    return [UIColor colorWithHexString:@"#daa520"];
}

- (UIColor *)lighterColor
{
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:MIN(b * 1.6, 1.0)
                               alpha:a];
    return nil;
}

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

@end
