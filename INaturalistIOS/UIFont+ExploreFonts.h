//
//  UIFont+ExploreFonts.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/28/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFont (ExploreFonts)

+ (instancetype)fontForTaxonRankName:(NSString *)rankName ofSize:(CGFloat)size;

@end
