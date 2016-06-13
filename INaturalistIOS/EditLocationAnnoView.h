//
//  EditLocationAnnoView.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/1/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditLocationAnnoView : UIView
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIColor *textColor;
- (UIView *)makeLabelView:(UILabel *)label rect:(CGRect)rect roundedCorner:(int)corner;
@end
