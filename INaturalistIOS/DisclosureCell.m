//
//  DisclosureCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/4/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
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
        
        self.secondaryLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label;
        });
        [self.contentView addSubview:self.secondaryLabel];
        
        [self setNeedsUpdateConstraints];
        
        NSDictionary *views = @{
                                @"iv": self.cellImageView,
                                @"title": self.titleLabel,
                                @"secondary": self.secondaryLabel,
                                };
        
        self.cellConstraints = [NSMutableArray array];

        [self.cellConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-7.5-[iv(==29)]"
                                                                                          options:0
                                                                                          metrics:0
                                                                                            views:views]];
        
        [self.cellConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[title]-0-|"
                                                                                          options:0
                                                                                          metrics:0
                                                                                            views:views]];
        [self.cellConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[secondary]-0-|"
                                                                                          options:0
                                                                                          metrics:0
                                                                                            views:views]];
        
        [self.cellConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[iv]-15-[title]-[secondary]-15-|"
                                                                                          options:0
                                                                                          metrics:0
                                                                                            views:views]];
        
        [self.cellConstraints addObject:[NSLayoutConstraint constraintWithItem:self.cellImageView
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.cellImageView
                                                                     attribute:NSLayoutAttributeHeight
                                                                    multiplier:1.0f
                                                                      constant:0.0f]];

    }
    
    return self;
}

- (void)updateConstraints {
    // TODO: this is slow and unwieldy
    
    if (self.cellConstraints && self.cellConstraints.count > 0) {
        [self removeConstraints:self.cellConstraints];
    }
    [self addConstraints:self.cellConstraints];
    
    [super updateConstraints];
}

- (void)prepareForReuse {
    [self.cellImageView sd_cancelCurrentImageLoad];
    self.cellImageView.layer.borderWidth = 0.0f;
    self.cellImageView.layer.borderColor = nil;
    self.cellImageView.layer.cornerRadius = 0.0f;
}


@end
