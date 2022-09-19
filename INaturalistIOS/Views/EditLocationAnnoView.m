//
//  EditLocationAnnoView.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/1/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "EditLocationAnnoView.h"
#import <QuartzCore/QuartzCore.h>

@implementation EditLocationAnnoView
@synthesize color = _color;
@synthesize textColor = _textColor;

- (void)setColor:(UIColor *)color
{
    _color = color;
    [self setNeedsDisplay];
}

- (UIColor *)color
{
    if (!_color) {
        _color = [[UIColor alloc] initWithRed:1 green:1 blue:1 alpha:0.75];
    }
    return _color;
}

- (UIColor *)textColor
{
    if (_textColor) return _textColor;
    if (!self.color) return [UIColor whiteColor];
    CGFloat hue, saturation, brightness, alpha;
    [self.color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    if (brightness < 0.5) {
        return [UIColor whiteColor];
    } else {
        return [UIColor blackColor];
    }
}

- (UIView *)makeLabelView:(UILabel *)label rect:(CGRect)rect roundedCorner:(int)corner;
{
    UIView *wrapper = [[UIView alloc] initWithFrame:rect];
    wrapper.backgroundColor = self.color;
//    I can't figure out how to resize the mask layer when the wrapper gets resized. Ugh.
//    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:wrapper.bounds
//                                                   byRoundingCorners:corner
//                                                         cornerRadii:CGSizeMake(5.0, 5.0)];
//    CAShapeLayer *maskLayer = [CAShapeLayer layer];
//    maskLayer.frame = wrapper.bounds;
//    maskLayer.path = maskPath.CGPath;
//    wrapper.layer.mask = maskLayer;
    
    label.frame = CGRectMake(5, 5, wrapper.frame.size.width - 10, wrapper.frame.size.height - 10);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = self.textColor;
    label.font = [UIFont systemFontOfSize:10.0];
    [wrapper addSubview:label];
    label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth;
    wrapper.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth;
    [wrapper setAutoresizesSubviews:YES];
    return wrapper;
}

@end
