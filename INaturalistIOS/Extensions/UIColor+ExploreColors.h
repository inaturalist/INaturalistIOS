//
//  UIColor+ExploreColors.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/20/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (ExploreColors)

+ (UIColor *)inatGreen;

// iconic taxa
+ (UIColor *)colorForIconicTaxon:(NSString *)iconicTaxon;

// notices
+ (UIColor *)colorForResearchGradeNotice;
+ (UIColor *)colorForIdPleaseNotice;
+ (UIColor *)secondaryColorForResearchGradeNotice;
+ (UIColor *)secondaryColorForIdPleaseNotice;

+ (UIColor *)inatBlack;
+ (UIColor *)inatGray;
+ (UIColor *)inatRed;

+ (UIColor *)mapOverlayColor;

- (UIColor *)lighterColor;
- (UIColor *)darkerColor;

@end
