//
//  ObservationViewCellUploading.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/29/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "ObservationViewUploadingCell.h"

@implementation ObservationViewUploadingCell

// would be great to do all of this autolayout stuff in the storyboard, but that means migrating the whole storyboard to AutoLayout
- (void)awakeFromNib {
    self.uploadSpinner.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *views = @{
                            @"imageView": self.observationImage,
                            @"title": self.titleLabel,
                            @"subtitle": self.subtitleLabel,
                            @"uploadSpinner": self.uploadSpinner,
                            };

    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[uploadSpinner(==30)]-8-|" options:0 metrics:0 views:views]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.uploadSpinner
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0f
                                                      constant:0.0f]];
}

@end
