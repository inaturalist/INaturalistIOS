//
//  ProjectPostCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/20/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "NewsItemCell.h"
#import "UIColor+INaturalist.h"

@interface NewsItemCell ()
@property NSLayoutConstraint *postImageViewWidthConstraint;
@end

@implementation NewsItemCell


- (void)awakeFromNib {
    self.newsCategoryImageView.layer.cornerRadius = 1.0f;
    self.newsCategoryImageView.layer.borderWidth = 0.5;
    self.newsCategoryImageView.layer.borderColor = [UIColor colorWithHexString:@"#C8C7CC"].CGColor;
    
    self.newsCategoryImageView.frame = CGRectZero;
    self.newsCategoryTitle.frame = CGRectZero;
    self.postedAt.frame = CGRectZero;
    self.postBody.frame = CGRectZero;
    self.postTitle.frame = CGRectZero;
    self.postImageView.frame = CGRectZero;
    
    self.newsCategoryImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.newsCategoryTitle.translatesAutoresizingMaskIntoConstraints = NO;
    self.postedAt.translatesAutoresizingMaskIntoConstraints = NO;
    self.postBody.translatesAutoresizingMaskIntoConstraints = NO;
    self.postTitle.translatesAutoresizingMaskIntoConstraints = NO;
    self.postImageView.translatesAutoresizingMaskIntoConstraints = NO;

    //self.postTitle.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.2f];
    //self.postBody.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.2f];
    
    [self.postTitle setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                    forAxis:UILayoutConstraintAxisVertical];
    [self.postTitle setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                      forAxis:UILayoutConstraintAxisVertical];
    
    [self.postBody setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                   forAxis:UILayoutConstraintAxisVertical];
    [self.postBody setContentHuggingPriority:UILayoutPriorityDefaultLow
                                     forAxis:UILayoutConstraintAxisVertical];

    
    NSDictionary *views = @{
                            @"categoryImageView": self.newsCategoryImageView,
                            @"categoryTitle": self.newsCategoryTitle,
                            @"postedAt": self.postedAt,
                            @"postBody": self.postBody,
                            @"postTitle": self.postTitle,
                            @"postImageView": self.postImageView,
                            };
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-15-[categoryImageView(==24)]-12-[categoryTitle]-[postedAt(==40)]-15-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-15-[postTitle]-15-[postImageView]-15-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-15-[postBody]-15-[postImageView]-15-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:views]];
    // this is a named constraint so we can adjust it as needed
    self.postImageViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.postImageView
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0f
                                                                      constant:0.0f];
    [self.contentView addConstraint:self.postImageViewWidthConstraint];
    
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-16-[categoryImageView(==24)]-10-[postTitle]-7-[postBody]-15-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:views]];
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-16-[categoryImageView(==24)]-10-[postTitle]-7-[postBody]-15-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:views]];
    
    /*
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[postImageView(==74)-16-|" options:<#(NSLayoutFormatOptions)#> metrics:<#(nullable NSDictionary<NSString *,id> *)#> views:<#(nonnull NSDictionary<NSString *,id> *)#>]]
     */
    
    // the relative time is the same y coord center as the category imageview
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.postedAt
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.newsCategoryImageView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0.0f]];
    // the category title is the same y coord center as the category imageview
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.postedAt
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.newsCategoryTitle
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0.0f]];
    
    // bottom of the post image view is aligned with the bottom of the post body
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.postImageView
                                                                 attribute:NSLayoutAttributeBottom
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.postBody
                                                                 attribute:NSLayoutAttributeBaseline
                                                                multiplier:1.0f
                                                                  constant:0.0f]];
    
    // height of the post image view is pegged at 74
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.postImageView
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1.0f
                                                                  constant:74.0f]];




}

- (void)prepareForReuse {
    [self.newsCategoryImageView sd_cancelCurrentImageLoad];
    self.newsCategoryImageView.image = nil;
    [self.postImageView sd_cancelCurrentImageLoad];
    self.postImageView.image = nil;
    
    self.newsCategoryTitle.text = nil;
    self.postedAt.text = nil;
    self.postBody.text = nil;
    self.postTitle.text = nil;
}

- (void)showPostImageView:(BOOL)shouldShow {
    if (shouldShow) {
        self.postImageViewWidthConstraint.constant = 74.0f;
    } else {
        self.postImageViewWidthConstraint.constant = 0.0f;
    }
}


@end
