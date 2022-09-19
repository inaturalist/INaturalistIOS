//
//  CrossHairView.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/29/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "CrossHairView.h"
#import <QuartzCore/QuartzCore.h>

@implementation CrossHairView

@synthesize xLabel = _xLabel;
@synthesize yLabel = _yLabel;

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
    self.xLabel.superview.frame = CGRectMake(self.bounds.size.width / 2.0,
                                             0,
                                             self.bounds.size.width / 4.0,
                                             20);
    self.yLabel.superview.frame = CGRectMake(self.bounds.size.width / 4.0 * 3,
                                              self.bounds.size.height / 2.0, 
                                              self.bounds.size.width / 4.0, 
                                              20);
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
