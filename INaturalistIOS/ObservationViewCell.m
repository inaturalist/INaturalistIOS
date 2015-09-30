//
//  ObservationViewCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/29/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "ObservationViewCell.h"

@implementation ObservationViewCell

- (void)awakeFromNib {
    self.observationImage.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.titleLabel.textAlignment = NSTextAlignmentNatural;
    self.subtitleLabel.textAlignment = NSTextAlignmentNatural;
    
    NSDictionary *views = @{
                            @"imageView": self.observationImage,
                            };

    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.subtitleLabel
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.titleLabel
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1
                                                      constant:0]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[imageView(==44)]-5-|"
                                                                 options:NSLayoutFormatAlignAllLeading
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[title(==subtitle)]-2-[subtitle]-4-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
}

@end
