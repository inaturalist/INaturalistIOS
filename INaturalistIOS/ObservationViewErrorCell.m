//
//  ObservationViewCellError.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/29/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonicons.h>

#import "ObservationViewErrorCell.h"

@implementation ObservationViewErrorCell

// would be great to do all of this autolayout stuff in the storyboard, but that means migrating the whole storyboard to AutoLayout
- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.validationErrorLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    FAKIcon *alert = [FAKIonIcons androidAlertIconWithSize:22];
    self.validationErrorLabel.attributedText = alert.attributedString;
    
    NSDictionary *views = @{
                            @"imageView": self.observationImage,
                            @"title": self.titleLabel,
                            @"subtitle": self.subtitleLabel,
                            @"dateLabel": self.dateLabel,
                            @"validationError": self.validationErrorLabel,
                            };

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[imageView(==44)]-[title]-[dateLabel(==46)]-16-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[imageView(==44)]-[subtitle]-[validationError(==24)]-16-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[dateLabel(==15)]->=0-[validationError(==22)]-5-|"
                                                                 options:NSLayoutFormatAlignAllTrailing
                                                                 metrics:0
                                                                   views:views]];

}


@end
