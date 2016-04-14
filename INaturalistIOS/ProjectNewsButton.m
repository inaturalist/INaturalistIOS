//
//  NewsButton.m
//  iNaturalist
//
//  Created by Alex Shepard on 4/14/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ProjectNewsButton.h"

@implementation ProjectNewsButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.newsTextLabel = [UILabel new];
        self.newsTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.newsTextLabel.font = [UIFont systemFontOfSize:12];
        self.newsTextLabel.textColor = [UIColor whiteColor];
        [self addSubview:self.newsTextLabel];
        
        self.countCircle = [UIView new];
        self.countCircle.translatesAutoresizingMaskIntoConstraints = NO;
        self.countCircle.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2f];
        self.countCircle.layer.cornerRadius = 19.0 / 2.0;
        self.countCircle.clipsToBounds = YES;
        [self addSubview:self.countCircle];
        
        self.countLabel = [UILabel new];
        self.countLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.countLabel.font = [UIFont systemFontOfSize:10];
        self.countLabel.textColor = [UIColor whiteColor];
        [self.countCircle addSubview:self.countLabel];
        
        NSDictionary *views = @{
                                @"text": self.newsTextLabel,
                                @"count": self.countLabel,
                                @"circle": self.countCircle,
                                };
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[text]-[circle(==19)]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[text]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.countCircle
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.countCircle
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0f
                                                          constant:19.0f]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.countLabel
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.countCircle
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.countLabel
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.countCircle
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        
    }
    
    return self;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end
