//
//  ObservationViewCell.m
//  iNaturalist
//
//  Created by Eldad Ohana on 7/2/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonicons.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ObservationViewNormalCell.h"
#import "UIColor+INaturalist.h"

@implementation ObservationViewNormalCell

// would be great to do all of this autolayout stuff in the storyboard, but that means migrating the whole storyboard to AutoLayout

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.activityButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.interactiveActivityButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *views = @{
                            @"imageView": self.observationImage,
                            @"title": self.titleLabel,
                            @"subtitle": self.subtitleLabel,
                            @"dateLabel": self.dateLabel,
                            @"activityButton": self.activityButton,
                            @"interactiveActivityButton": self.interactiveActivityButton,
                            };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[imageView(==44)]-[title]-[dateLabel(==46)]-16-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[imageView(==44)]-[subtitle]-[activityButton(==24)]-18-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[interactiveActivityButton]-5-|"
                                                                 options:NSLayoutFormatAlignAllTrailing
                                                                 metrics:0
                                                                   views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[interactiveActivityButton(==44)]-16-|"
                                                                 options:NSLayoutFormatAlignAllTrailing
                                                                 metrics:0
                                                                   views:views]];
    
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[dateLabel(==15)]->=0-[activityButton(==22)]-7-|"
                                                                 options:NSLayoutFormatAlignAllTrailing
                                                                 metrics:0
                                                                   views:views]];
    
}

@end
