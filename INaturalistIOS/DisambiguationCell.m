//
//  DisambiguationCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/3/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "DisambiguationCell.h"
#import "UIColor+ExploreColors.h"

@implementation DisambiguationCell

// designated initializer for UITableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.resultImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.contentMode = UIViewContentModeScaleAspectFit;
            
            iv;
        });
        [self.contentView addSubview:self.resultImageView];
        
        self.resultTitle = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor colorForIconicTaxon:nil];
            label.font = [UIFont boldSystemFontOfSize:14.0f];
            
            label;
        });
        [self.contentView addSubview:self.resultTitle];
        
        self.resultSubtitle = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor inatGray];
            label.font = [UIFont italicSystemFontOfSize:11.0f];
            
            label;
        });
        [self.contentView addSubview:self.resultSubtitle];
        
        NSDictionary *views = @{
                                @"resultImageView": self.resultImageView,
                                @"resultTitle": self.resultTitle,
                                @"resultSubtitle": self.resultSubtitle,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-2-[resultImageView(==40)]-[resultTitle]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[resultTitle]-5-[resultSubtitle]-5-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[resultImageView]-2-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.resultSubtitle
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.resultTitle
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0f
                                                          constant:0.0f]];
    }
    
    return self;
}

- (void)prepareForReuse {
    self.resultImageView.image = nil;
    self.resultTitle.text = nil;
    self.resultSubtitle.text = nil;
}

@end
