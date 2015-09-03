//
//  ObservationViewCell.m
//  iNaturalist
//
//  Created by Eldad Ohana on 7/2/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonicons.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ObservationViewCell.h"
#import "UIColor+INaturalist.h"

@implementation ObservationViewCell


- (void)awakeFromNib{
    self.observationImage.translatesAutoresizingMaskIntoConstraints = NO;
    self.activityButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.interactiveActivityButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.uploadButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.uploadSpinner.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.titleLabel.textAlignment = NSTextAlignmentNatural;
    self.subtitleLabel.textAlignment = NSTextAlignmentNatural;
    
    self.uploadSpinner.color = [UIColor whiteColor];
    self.uploadSpinner.hidden = YES;
    
    FAKIcon *upload = [FAKIonIcons iosCloudUploadIconWithSize:30];
    [upload addAttribute:NSForegroundColorAttributeName
                   value:[UIColor inatTint]];
    [self.uploadButton setAttributedTitle:upload.attributedString
                                 forState:UIControlStateNormal];
    
    [upload addAttribute:NSForegroundColorAttributeName
                   value:[UIColor lightGrayColor]];
    [self.uploadButton setAttributedTitle:upload.attributedString
                                 forState:UIControlStateDisabled];

    NSDictionary *views = @{
                            @"imageView":self.observationImage,
                            @"title":self.titleLabel,
                            @"subtitle":self.subtitleLabel,
                            @"dateLabel":self.dateLabel,
                            @"activityButton": self.activityButton,
                            @"interactiveActivityButton":self.interactiveActivityButton,
                            @"uploadButton":self.uploadButton,
                            @"uploadSpinner": self.uploadSpinner
                            };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[imageView(==44)]-[title]-[dateLabel(==46)]-6-|" options:0 metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView(==44)]-[subtitle]-[activityButton(==24)]-8-|" options:0 metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[imageView(==44)]->=0-|" options:NSLayoutFormatAlignAllLeading metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[interactiveActivityButton]-5-|" options:NSLayoutFormatAlignAllTrailing metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[interactiveActivityButton(==44)]-5-|" options:NSLayoutFormatAlignAllTrailing metrics:0 views:views]];
    
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[uploadButton(==44)]-0-|" options:0 metrics:0 views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[uploadButton]-0-|" options:0 metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[uploadSpinner(==30)]-8-|" options:0 metrics:0 views:views]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.uploadSpinner
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[title(==subtitle)]-2-[subtitle]-4-|" options:0 metrics:0 views:views]];

    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.subtitleLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.titleLabel attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[dateLabel(==15)]->=0-[activityButton(==22)]-3-|" options:NSLayoutFormatAlignAllTrailing metrics:0 views:views]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.subtitleLabel attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
}

- (void)prepareForReuse {
    self.uploadSpinner.hidden = YES;
}


@end
