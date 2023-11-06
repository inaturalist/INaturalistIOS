//
//  UIColor+INaturalist.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/13/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (INaturalist)
+ (UIColor *)inatDarkGreen;
+ (UIColor *)inatTint;
+ (UIColor *)inatInactiveGreyTint;
+ (UIColor *)inatDarkGray;
+ (UIColor *)inatLightGray;
+ (UIColor *)inatTableViewBackgroundGray;
+ (UIColor *)inatBlack;
+ (UIColor *)inatGray;
+ (UIColor *)inatRed;

// iconic taxa
+ (UIColor *)colorForIconicTaxon:(NSString *)iconicTaxon;

// explore UI
+ (UIColor *)colorForResearchGradeNotice;
+ (UIColor *)secondaryColorForResearchGradeNotice;
+ (UIColor *)mapOverlayColor;

// helper
- (UIColor *)darkerColor;
@end
