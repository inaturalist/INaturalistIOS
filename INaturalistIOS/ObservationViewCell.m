//
//  ObservationViewCell.m
//  iNaturalist
//
//  Created by Eldad Ohana on 7/2/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "ObservationViewCell.h"
static const int ObservationCellImageTag = 5;
static const int ObservationCellTitleTag = 1;
static const int ObservationCellSubTitleTag = 2;
static const int ObservationCellUpperRightTag = 3;
static const int ObservationCellLowerRightTag = 4;
static const int ObservationCellActivityButtonTag = 6;
static const int ObservationCellActivityInteractiveButtonTag = 7;
@implementation ObservationViewCell


- (void)awakeFromNib{
    
    UIImageView *imageView = (UIImageView *)[self viewWithTag:ObservationCellImageTag];
    UILabel *title = (UILabel *)[self viewWithTag:ObservationCellTitleTag];
    UILabel *subtitle = (UILabel *)[self viewWithTag:ObservationCellSubTitleTag];
    UILabel *upperRight = (UILabel *)[self viewWithTag:ObservationCellUpperRightTag];
    UIImageView *syncImage = (UIImageView *)[self viewWithTag:ObservationCellLowerRightTag];
    UIButton *activityButton = (UIButton *)[self viewWithTag:ObservationCellActivityButtonTag];
    UIButton *interactiveActivityButton = (UIButton *)[self viewWithTag:ObservationCellActivityInteractiveButtonTag];
    
    
    if(!self.constraints.count){
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        syncImage.translatesAutoresizingMaskIntoConstraints = NO;
        activityButton.translatesAutoresizingMaskIntoConstraints = NO;
        interactiveActivityButton.translatesAutoresizingMaskIntoConstraints = NO;
        title.translatesAutoresizingMaskIntoConstraints = NO;
        subtitle.translatesAutoresizingMaskIntoConstraints = NO;
        upperRight.translatesAutoresizingMaskIntoConstraints = NO;
        
        title.textAlignment = NSTextAlignmentNatural;
        subtitle.textAlignment = NSTextAlignmentNatural;
        
//        title.preferredMaxLayoutWidth = self.frame.size.width;
//        subtitle.preferredMaxLayoutWidth = self.frame.size.width;
        interactiveActivityButton.backgroundColor = [UIColor redColor];
        title.backgroundColor = [UIColor redColor];
        subtitle.backgroundColor = [UIColor redColor];
        
        self.backgroundColor = [UIColor greenColor];
        
        NSDictionary *views = @{@"imageView":imageView,@"syncImage": syncImage,@"title":title,@"subtitle":subtitle,@"upperRight":upperRight,@"activityButton": activityButton,@"interactiveActivityButton":interactiveActivityButton};
        
        NSDictionary *matrics = @{@"imagePadding":@5, @"rightPadding":@4};
        
        
        [title setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [title setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        [subtitle setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [subtitle setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        //        [self.contentView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        //
        //        [imageView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        //        [imageView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        //
        //        [title setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
//        [title setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        //
        //        [subtitle setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
//        [subtitle setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        //
        //        [upperRight setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        //
        //
        //        [activityButton setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        //
        //
        //        [interactiveActivityButton setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        //
        //
        //        [syncImage setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-imagePadding-[imageView(==44)]-[title]-[upperRight(==43)]|" options:0 metrics:matrics views:views]];
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-imagePadding-[imageView(==44)]-imagePadding-|" options:0 metrics:matrics views:views]];
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-imagePadding-[imageView(==44)]-[subtitle]-[syncImage(==16)]-[activityButton(==24)]-rightPadding-|" options:0 metrics:matrics views:views]];
        

        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-imagePadding-[title]-2-[subtitle]-imagePadding-|" options:0 metrics:matrics views:views]];
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[interactiveActivityButton(==35)]-|" options:0 metrics:matrics views:views]];
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[interactiveActivityButton]-|" options:0 metrics:matrics views:views]];
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[syncImage(==16)]-rightPadding-|" options:0 metrics:matrics views:views]];
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[upperRight(==15)]-[activityButton(==22)]-rightPadding-|" options:0 metrics:matrics views:views]];
        
        
    }
    
    
}
@end
