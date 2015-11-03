//
//  SubtitleDisclosureCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/9/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "SubtitleDisclosureCell.h"

@implementation SubtitleDisclosureCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.subtitleLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.font = [UIFont systemFontOfSize:11.0f];
            label.textColor = [UIColor colorWithHexString:@"#8e8e8e"];
            
            label;
        });
        [self.contentView addSubview:self.subtitleLabel];
        
        NSDictionary *views = @{
                                @"iv": self.cellImageView,
                                @"title": self.titleLabel,
                                @"subtitle": self.subtitleLabel,
                                @"secondary": self.secondaryLabel,
                                };
        
        
        self.cellConstraints = [NSMutableArray array];
        [self.cellConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-7.5-[iv(==29)]"
                                                                                          options:0
                                                                                          metrics:0
                                                                                            views:views]];
        [self.cellConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[title]-[subtitle]-|"
                                                                                          options:0
                                                                                          metrics:0
                                                                                            views:views]];
        [self.cellConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[secondary]-0-|"
                                                                                          options:0
                                                                                          metrics:0
                                                                                            views:views]];
        
        [self.cellConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[iv]-15-[title]-[secondary]-10-|"
                                                                                          options:0
                                                                                          metrics:0
                                                                                            views:views]];
        [self.cellConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[iv]-15-[subtitle]-[secondary]-10-|"
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
        
        [self.cellConstraints addObject:[NSLayoutConstraint constraintWithItem:self.subtitleLabel
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.titleLabel
                                                                     attribute:NSLayoutAttributeHeight
                                                                    multiplier:1.0f
                                                                      constant:0.0f]];
    
    }
    
    return self;
}


@end
