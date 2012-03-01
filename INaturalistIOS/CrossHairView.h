//
//  CrossHairView.h
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/29/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CrossHairView : UIView
@property (nonatomic, strong) UILabel *xLabel;
@property (nonatomic, strong) UILabel *yLabel;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIColor *textColor;

- (void)initSubviews;
- (UIView *)makeLabelView:(UILabel *)label rect:(CGRect)rect roundedCorner:(int)corner;
@end
