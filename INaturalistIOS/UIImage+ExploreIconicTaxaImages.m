//
//  UIImage+ExploreIconicTaxaImages.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/22/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "UIImage+ExploreIconicTaxaImages.h"

@implementation UIImage (ExploreIconicTaxaImages)

+ (UIImage *)imageForIconicTaxon:(NSString *)iconicTaxon {
    
    NSString *candidateName = [NSString stringWithFormat:@"%@-200px.png", [iconicTaxon lowercaseString]];
    UIImage *candidate = [UIImage imageNamed:candidateName];
    
    if (candidate)
        return candidate;
    else
        return [UIImage imageNamed:@"unknown-200px.png"];
}

@end
