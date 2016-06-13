//
//  UIFont+ExploreFonts.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/28/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "UIFont+ExploreFonts.h"

@implementation UIFont (ExploreFonts)

// from kueda: You could also only italicize when rank is genus, species, subspecies, or variety
// (omits some other minor infraspecific taxa, but not many)
+ (instancetype)fontForTaxonRankName:(NSString *)rankName ofSize:(CGFloat)size {
    if ([rankName isEqualToString:@"genus"] ||
        [rankName isEqualToString:@"species"] ||
        [rankName isEqualToString:@"subspecies"] ||
        [rankName isEqualToString:@"variety"]) {
        
        return [UIFont italicSystemFontOfSize:size];
    } else {
        return [UIFont systemFontOfSize:size];
    }
}

@end
