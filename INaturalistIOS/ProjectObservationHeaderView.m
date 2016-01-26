//
//  ProjectObservationHeaderView.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "UIColor-HTMLColors/UIColor+HTMLColors.h"

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
            
            label.textColor = [UIColor blackColor];
            label.font = [UIFont systemFontOfSize:17.0f];
            
            label.numberOfLines = 2;
            [label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
            
            label;
        });
        [self addSubview:self.projectTitleLabel];
        
        self.projectThumbnailImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.layer.cornerRadius = 2.0f;
            iv.layer.borderColor = [UIColor colorWithHexString:@"#aaaaaa"].CGColor;
            iv.layer.borderWidth = 1.0f;
            iv.clipsToBounds = YES;
            
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
            
            view.backgroundColor = [UIColor colorWithHexString:@"#C8C7CC"];
            
            view;
        });
        [self addSubview:edge];
        
        self.infoButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoDark];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            button.hidden = YES;
            
            button;
        });
        [self addSubview:self.infoButton];
        
        NSDictionary *views = @{
                                @"title": self.projectTitleLabel,
                                @"thumb": self.projectThumbnailImageView,
                                @"switch": self.selectedSwitch,
                                @"edge": edge,
                                @"info": self.infoButton,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-15-[thumb(==29)]-15-[title]-[switch]-15-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-59-[edge]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[edge(==0.5)]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.infoButton
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.infoButton
                                                         attribute:NSLayoutAttributeRight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeRight
                                                        multiplier:1.0f
                                                          constant:-10]];
        
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
