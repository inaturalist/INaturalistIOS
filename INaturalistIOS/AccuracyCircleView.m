//
//  AccuracyCircleView.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/1/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "AccuracyCircleView.h"
#import <QuartzCore/QuartzCore.h>

@implementation AccuracyCircleView

@synthesize radius = _radius;
@synthesize label = _label;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.label = [[UILabel alloc] init];
        self.label.text = @"Acc: ???";
        [self addSubview:[self makeLabelView:self.label 
                                        rect:CGRectMake(self.frame.size.width / 4.0,
                                                        self.frame.size.height - 20,
                                                        self.frame.size.width / 4.0,
                                                        20) 
                               roundedCorner:UIRectCornerTopLeft]];
    }
    return self;
}

- (void)setRadius:(float)radius
{
    _radius = radius;
    [self setNeedsDisplay];
}

- (float)radius
{
    if (!_radius) {
        _radius = 0.0;
    }
    return _radius;
}

- (void)layoutSubviews
{
    CGFloat w = self.frame.size.width,
            h = self.frame.size.height;
    UIView *labelWrapper = self.label.superview;
    labelWrapper.frame = CGRectMake(w / 4.0,
                                    h - labelWrapper.frame.size.height,
                                    w / 4.0,
                                    labelWrapper.frame.size.height);
    labelWrapper.layer.mask.frame = labelWrapper.bounds;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.color setStroke];
    CGContextAddArc(context,
                    self.bounds.size.width / 2.0, 
                    self.bounds.size.height / 2.0, 
                    self.radius, 
                    0, 
                    2 * M_PI, 
                    0);
    CGContextStrokePath(context);
}
@end
