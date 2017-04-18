//
//  ProjectPostCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/20/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "NewsItemCell.h"
#import "UIColor+INaturalist.h"

@interface NewsItemCell ()
@property NSLayoutConstraint *postImageViewWidthConstraint;
@end

@implementation NewsItemCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.newsCategoryImageView = [UIImageView new];
        self.newsCategoryImageView.layer.cornerRadius = 1.0f;
        self.newsCategoryImageView.layer.borderWidth = 0.5;
        self.newsCategoryImageView.layer.borderColor = [UIColor colorWithHexString:@"#C8C7CC"].CGColor;
        self.newsCategoryImageView.frame = CGRectZero;
        self.newsCategoryImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.newsCategoryImageView];
        
        self.postImageView = [UIImageView new];
        self.postImageView.frame = CGRectZero;
        self.postImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.postImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.postImageView.clipsToBounds = YES;
        [self.contentView addSubview:self.postImageView];
        
        self.newsCategoryTitle = [UILabel new];
        self.newsCategoryTitle.textColor = [UIColor blackColor];
        self.newsCategoryTitle.font = [UIFont systemFontOfSize:15];
        self.newsCategoryTitle.frame = CGRectZero;
        self.newsCategoryTitle.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.newsCategoryTitle];
        
        self.postedAt = [UILabel new];
        self.postedAt.textColor = [UIColor colorWithHexString:@"#aaaaaa"];
        self.postedAt.font = [UIFont systemFontOfSize:15];
        self.postedAt.frame = CGRectZero;
        self.postedAt.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.postedAt];
        
        self.postBody = [UILabel new];
        self.postBody.textColor = [UIColor colorWithHexString:@"#686868"];
        self.postBody.font = [UIFont systemFontOfSize:14];
        self.postBody.numberOfLines = 0;
        self.postBody.frame = CGRectZero;
        self.postBody.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.postBody];
        
        self.postTitle = [UILabel new];
        self.postTitle.textColor = [UIColor blackColor];
        self.postTitle.font = [UIFont boldSystemFontOfSize:16];
        self.postTitle.numberOfLines = 0;
        self.postTitle.frame = CGRectZero;
        self.postTitle.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.postTitle];
        
        // allow body to flow up into the space left by post title if it only needs a single line
        // if the title fits on a single line, we'll use a three line body excerpt. if the title
        // needs two lines, we'll only use a two line body excerpt. yay layout priority!
        [self.postTitle setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                        forAxis:UILayoutConstraintAxisVertical];
        [self.postTitle setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                          forAxis:UILayoutConstraintAxisVertical];
        
        [self.postBody setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                       forAxis:UILayoutConstraintAxisVertical];
        [self.postBody setContentHuggingPriority:UILayoutPriorityDefaultLow
                                         forAxis:UILayoutConstraintAxisVertical];
        
        // posted at shouldn't truncate, should make as much space as possible for the category title
        [self.postedAt setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                       forAxis:UILayoutConstraintAxisHorizontal];
        [self.postedAt setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                         forAxis:UILayoutConstraintAxisHorizontal];
        
        // category title can truncate
        [self.newsCategoryTitle setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                                forAxis:UILayoutConstraintAxisHorizontal];
        [self.newsCategoryTitle setContentHuggingPriority:UILayoutPriorityDefaultLow
                                                  forAxis:UILayoutConstraintAxisHorizontal];
        
        NSDictionary *views = @{
                                @"categoryImageView": self.newsCategoryImageView,
                                @"categoryTitle": self.newsCategoryTitle,
                                @"postedAt": self.postedAt,
                                @"postBody": self.postBody,
                                @"postTitle": self.postTitle,
                                @"postImageView": self.postImageView,
                                };
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-15-[categoryImageView(==24)]-12-[categoryTitle]-[postedAt]-15-|"
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
        
        // bottom of the post image view is aligned with the baseline of the post body
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
    
    return self;
}

- (void)prepareForReuse {
    [self.newsCategoryImageView cancelImageRequestOperation];
    self.newsCategoryImageView.image = nil;
    [self.postImageView cancelImageRequestOperation];
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
