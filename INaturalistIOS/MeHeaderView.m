//
//  MeHeaderView.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/11/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "MeHeaderView.h"

@implementation MeHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor whiteColor];
        
        self.iconImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.layer.borderColor = [UIColor grayColor].CGColor;
            iv.layer.borderWidth = 0.5f;
            iv.layer.cornerRadius = 40.0f;      // circular with an 80x80 frame
            
            iv.clipsToBounds = YES;
            
            iv;
        });
        [self addSubview:self.iconImageView];
        
        self.nameLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.font = [UIFont systemFontOfSize:18.0f];
            label.textColor = [UIColor darkGrayColor];
            label.textAlignment = NSTextAlignmentCenter;
            
            label;
        });
        [self addSubview:self.nameLabel];
        
        self.obsCountLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.font = [UIFont systemFontOfSize:14.0f];
            label.textColor = [UIColor grayColor];
            label.textAlignment = NSTextAlignmentCenter;

            label;
        });
        [self addSubview:self.obsCountLabel];
        
        self.idsCountLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.font = [UIFont systemFontOfSize:14.0f];
            label.textColor = [UIColor grayColor];
            label.textAlignment = NSTextAlignmentCenter;
            
            label;
        });
        [self addSubview:self.idsCountLabel];

        
        NSDictionary *views = @{
                                @"icon": self.iconImageView,
                                @"name": self.nameLabel,
                                @"obsCount": self.obsCountLabel,
                                @"idsCount": self.idsCountLabel,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-20-[icon(==80)]-[name]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-20-[icon(==80)]-[obsCount]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-20-[icon(==80)]-[idsCount]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[name]-10-[obsCount]-5-[idsCount]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.iconImageView
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.iconImageView
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0f
                                                          constant:80.0f]];

        
    }
    
    return self;
}
@end
