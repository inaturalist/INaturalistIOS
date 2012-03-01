//
//  CrossHairView.m
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/29/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "CrossHairView.h"
#import <QuartzCore/QuartzCore.h>

@implementation CrossHairView

@synthesize xLabel = _xLabel;
@synthesize yLabel = _yLabel;
@synthesize color = _color;
@synthesize textColor = _textColor;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews
{
    self.xLabel = [[UILabel alloc] init];
    self.xLabel.text = @"x";
    self.yLabel = [[UILabel alloc] init];
    self.yLabel.text = @"y";
    [self addSubview:[self makeLabelView:self.xLabel 
                                    rect:CGRectMake(self.bounds.size.width / 2.0 + 1, 0, self.bounds.size.width / 4.0, 20) 
                           roundedCorner:UIRectCornerBottomRight]];
    [self addSubview:[self makeLabelView:self.yLabel 
                                    rect:CGRectMake(self.bounds.size.width / 4.0 * 3, 
                                                    self.bounds.size.height / 2.0, 
                                                    self.bounds.size.width / 4.0, 
                                                    20)
                           roundedCorner:UIRectCornerBottomLeft]];
}

- (void)layoutSubviews
{
    self.yLabel.superview.frame = CGRectMake(self.bounds.size.width / 4.0 * 3, 
                                              self.bounds.size.height / 2.0, 
                                              self.bounds.size.width / 4.0, 
                                              20);
}

- (UIView *)makeLabelView:(UILabel *)label rect:(CGRect)rect roundedCorner:(int)corner;
{
    UIView *wrapper = [[UIView alloc] initWithFrame:rect];
    wrapper.backgroundColor = self.color;
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:wrapper.bounds 
                                                   byRoundingCorners:corner
                                                         cornerRadii:CGSizeMake(5.0, 5.0)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = wrapper.bounds;
    maskLayer.path = maskPath.CGPath;
    wrapper.layer.mask = maskLayer;
    
    label.frame = CGRectMake(5, 5, wrapper.frame.size.width - 10, wrapper.frame.size.height - 10);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = self.textColor;
    label.font = [UIFont systemFontOfSize:10.0];
    [wrapper addSubview:label];
    return wrapper;
}

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
    NSLog(@"brightness: %f", brightness);
    if (brightness < 0.5) {
        return [UIColor whiteColor];
    } else {
        return [UIColor blackColor];
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetAllowsAntialiasing(context, false);
    CGContextSetLineWidth(context, 1);
    [self.color setStroke];
    CGContextMoveToPoint(context, self.bounds.origin.x, self.bounds.size.height / 2.0);
    CGContextAddLineToPoint(context, self.bounds.size.width, self.bounds.size.height / 2.0);
    CGContextMoveToPoint(context, self.bounds.size.width / 2.0, self.bounds.origin.y);
    CGContextAddLineToPoint(context, self.bounds.size.width / 2.0, self.bounds.size.height);
    CGContextStrokePath(context);
}


@end
