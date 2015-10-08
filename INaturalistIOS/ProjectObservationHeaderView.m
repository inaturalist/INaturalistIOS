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
            label.font = [UIFont systemFontOfSize:14.0f];
            
            label.numberOfLines = 2;
            [label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
            
            label;
        });
        [self addSubview:self.projectTitleLabel];
        
        self.projectThumbnailImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv;
        });
        [self addSubview:self.projectThumbnailImageView];
        
        self.selectedSwitch = ({
            UISwitch *switcher = [[UISwitch alloc] initWithFrame:CGRectZero];
            switcher.translatesAutoresizingMaskIntoConstraints = NO;
            
            switcher;
        });
        [self addSubview:self.selectedSwitch];
        
        self.detailsLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor darkGrayColor];
            label.font = [UIFont systemFontOfSize:11.0f];
            
            label.text = NSLocalizedString(@"Project-specific observation details", @"details subtitle for project chooser rows");
            
            label;
        });
        [self addSubview:self.detailsLabel];
        
        UIView *edge = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            
            view.backgroundColor = [UIColor lightGrayColor];
            
            view;
        });
        [self addSubview:edge];
        
        
        NSDictionary *views = @{
                                @"title": self.projectTitleLabel,
                                @"details": self.detailsLabel,
                                @"thumb": self.projectThumbnailImageView,
                                @"switch": self.selectedSwitch,
                                @"edge": edge,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[thumb(==40)]-[title]-[switch]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[thumb(==40)]-[details]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[edge]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[edge(==0.5)]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
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
                                                          constant:2.0f]];
        
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
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.detailsLabel
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0f
                                                          constant:-2.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.detailsLabel
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0f
                                                          constant:22]];
        
    }
    
    return self;
}

@end
