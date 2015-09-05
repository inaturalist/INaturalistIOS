//
//  DisclosureCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/4/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "DisclosureCell.h"

@implementation DisclosureCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.cellImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            
            iv;
        });
        [self.contentView addSubview:self.cellImageView];
        
        self.titleLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            
            label;
        });
        [self.contentView addSubview:self.titleLabel];

        self.subtitleLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            
            label;
        });
        [self.contentView addSubview:self.subtitleLabel];

        NSDictionary *views = @{
                                @"iv": self.cellImageView,
                                @"title": self.titleLabel,
                                @"subtitle": self.subtitleLabel,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[iv]-5-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[title]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[subtitle]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[iv]-12-[title]-[subtitle]-10-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.cellImageView
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.cellImageView
                                                         attribute:NSLayoutAttributeHeight
                                                        multiplier:1.0f
                                                          constant:0.0f]];


    }
    
    return self;
}


@end
