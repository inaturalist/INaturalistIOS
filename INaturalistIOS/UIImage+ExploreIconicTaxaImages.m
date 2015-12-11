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
    
    NSString *candidateName = [NSString stringWithFormat:@"ic_%@", [iconicTaxon lowercaseString]];
    UIImage *candidate = [UIImage imageNamed:candidateName];
    
    if (candidate)
        return candidate;
    else
        return [UIImage imageNamed:@"ic_unknown"];
}

@end
