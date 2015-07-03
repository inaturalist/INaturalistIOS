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
    
    
    UIImageView *imageView = (UIImageView *)[self viewWithTag:ObservationCellImageTag];
    UILabel *title = (UILabel *)[self viewWithTag:ObservationCellTitleTag];
    UILabel *subtitle = (UILabel *)[self viewWithTag:ObservationCellSubTitleTag];
    UILabel *upperRight = (UILabel *)[self viewWithTag:ObservationCellUpperRightTag];
    UIImageView *syncImage = (UIImageView *)[self viewWithTag:ObservationCellLowerRightTag];
    UIButton *activityButton = (UIButton *)[self viewWithTag:ObservationCellActivityButtonTag];
    UIButton *interactiveActivityButton = (UIButton *)[self viewWithTag:ObservationCellActivityInteractiveButtonTag];
    
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    syncImage.translatesAutoresizingMaskIntoConstraints = NO;
    activityButton.translatesAutoresizingMaskIntoConstraints = NO;
    interactiveActivityButton.translatesAutoresizingMaskIntoConstraints = NO;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    upperRight.translatesAutoresizingMaskIntoConstraints = NO;

        
    title.textAlignment = NSTextAlignmentNatural;
    subtitle.textAlignment = NSTextAlignmentNatural;
        
        
    NSDictionary *views = @{@"imageView":imageView,@"title":title,@"subtitle":subtitle,@"upperRight":upperRight,@"activityButton": activityButton, @"interactiveActivityButton":interactiveActivityButton, @"syncImage":syncImage};
        
        
        
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[imageView(==44)]-[title]-[upperRight(==46)]-3-|" options:0 metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView(==44)]-[subtitle]-[syncImage(==16)]-[activityButton(==24)]-3-|" options:0 metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[imageView(==44)]->=0-|" options:NSLayoutFormatAlignAllLeading metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[interactiveActivityButton]-5-|" options:NSLayoutFormatAlignAllTrailing metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[interactiveActivityButton(==44)]-5-|" options:NSLayoutFormatAlignAllTrailing metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[syncImage(==16)]-5-|" options:0 metrics:0 views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[title(==subtitle)]-2-[subtitle]-4-|" options:0 metrics:0 views:views]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:subtitle attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:title attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[upperRight(==15)]->=0-[activityButton(==22)]-3-|" options:NSLayoutFormatAlignAllTrailing metrics:0 views:views]];
    
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:title attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:subtitle attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
}



@end
