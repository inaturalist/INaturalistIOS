//
//  AccuracyCircleView.m
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 3/1/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "AccuracyCircleView.h"

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
                                        rect:CGRectMake(self.bounds.size.width / 4.0, 
                                                        self.bounds.size.height - 20, 
                                                        self.bounds.size.width / 4.0, 
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
    self.label.superview.frame = CGRectMake(self.bounds.size.width / 4.0, 
                                            self.bounds.size.height - 20, 
                                            self.bounds.size.width / 4.0, 
                                            20);
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
