//
//  ObservationViewCell.m
//  iNaturalist
//
//  Created by Eldad Ohana on 7/2/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "ObservationViewCell.h"

@implementation ObservationViewCell


- (void)awakeFromNib{
    self.observationImage.translatesAutoresizingMaskIntoConstraints = NO;
    self.syncImage.translatesAutoresizingMaskIntoConstraints = NO;
    self.activityButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.interactiveActivityButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.uploadButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.titleLabel.textAlignment = NSTextAlignmentNatural;
    self.subtitleLabel.textAlignment = NSTextAlignmentNatural;
        
    NSDictionary *views = @{@"imageView":self.observationImage,@"title":self.titleLabel,@"subtitle":self.subtitleLabel,@"dateLabel":self.dateLabel,@"activityButton": self.activityButton, @"interactiveActivityButton":self.interactiveActivityButton, @"syncImage":self.syncImage, @"uploadButton":self.uploadButton};
        
        
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[imageView(==44)]-[title]-[dateLabel(==46)]-6-|" options:0 metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView(==44)]-[subtitle]-[syncImage(==16)]-[activityButton(==24)]-8-|" options:0 metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[imageView(==44)]->=0-|" options:NSLayoutFormatAlignAllLeading metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[interactiveActivityButton]-5-|" options:NSLayoutFormatAlignAllTrailing metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[interactiveActivityButton(==44)]-5-|" options:NSLayoutFormatAlignAllTrailing metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[syncImage(==16)]-5-|" options:0 metrics:0 views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[uploadButton(==30)]-4-|" options:0 metrics:0 views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[uploadButton]-0-|" options:0 metrics:0 views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[title(==subtitle)]-2-[subtitle]-4-|" options:0 metrics:0 views:views]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.subtitleLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.titleLabel attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[dateLabel(==15)]->=0-[activityButton(==22)]-3-|" options:NSLayoutFormatAlignAllTrailing metrics:0 views:views]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.subtitleLabel attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
}



@end
