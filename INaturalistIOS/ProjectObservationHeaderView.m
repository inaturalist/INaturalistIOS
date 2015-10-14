//
//  ProjectObservationHeaderView.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "ProjectObservationHeaderView.h"

@interface ProjectObservationHeaderView ()

@end

@implementation ProjectObservationHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor whiteColor];
        
        self.projectTitleLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor darkGrayColor];
            label.font = [UIFont systemFontOfSize:16.0f];
            
            label.numberOfLines = 2;
            [label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
            
            label;
        });
        [self addSubview:self.projectTitleLabel];
        
        self.projectThumbnailImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.layer.cornerRadius = 0.5f;
            
            iv;
        });
        [self addSubview:self.projectThumbnailImageView];
        
        self.selectedSwitch = ({
            UISwitch *switcher = [[UISwitch alloc] initWithFrame:CGRectZero];
            switcher.translatesAutoresizingMaskIntoConstraints = NO;
            
            switcher;
        });
        [self addSubview:self.selectedSwitch];
                
        UIView *edge = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            
            view.backgroundColor = [UIColor lightGrayColor];
            
            view;
        });
        [self addSubview:edge];
        
        
        NSDictionary *views = @{
                                @"title": self.projectTitleLabel,
                                @"thumb": self.projectThumbnailImageView,
                                @"switch": self.selectedSwitch,
                                @"edge": edge,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-8.5-[thumb(==27)]-[title]-[switch]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-8.5-[thumb(==27)]-[edge]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:edge
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0f
                                                          constant:0.5f]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:edge
                                                         attribute:NSLayoutAttributeTrailing
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeTrailing
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.projectThumbnailImageView
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.projectThumbnailImageView
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.projectThumbnailImageView
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0f
                                                          constant:8.5]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.projectTitleLabel
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.projectThumbnailImageView
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.selectedSwitch
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.projectThumbnailImageView
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        
    }
    
    return self;
}

@end
