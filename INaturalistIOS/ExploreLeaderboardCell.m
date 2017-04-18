//
//  ExploreLeaderboardCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/18/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>

#import "ExploreLeaderboardCell.h"

@implementation ExploreLeaderboardCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.rank = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor grayColor];
            label.textAlignment = NSTextAlignmentRight;
            
            label;
        });
        [self.contentView addSubview:self.rank];
        
        self.userIcon = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.layer.cornerRadius = 25;
            iv.layer.borderColor = [UIColor grayColor].CGColor;
            iv.layer.borderWidth = 0.5f;
            iv.clipsToBounds = YES;
            
            iv;
        });
        [self.contentView addSubview:self.userIcon];
        
        self.username = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor grayColor];
            label.textAlignment = NSTextAlignmentLeft;
            label.font = [UIFont systemFontOfSize:14.0f];
            
            label;
        });
        [self.contentView addSubview:self.username];
        
        self.observationCount = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor grayColor];
            label.textAlignment = NSTextAlignmentLeft;
            label.font = [UIFont systemFontOfSize:11.0f];
            
            label;
        });
        [self.contentView addSubview:self.observationCount];

        self.speciesCount = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor grayColor];
            label.textAlignment = NSTextAlignmentLeft;
            label.font = [UIFont systemFontOfSize:11.0f];
            
            label;
        });
        [self.contentView addSubview:self.speciesCount];
        
        self.sortControl = ({
            UIControl *control = [[UIControl alloc] initWithFrame:CGRectZero];
            control.translatesAutoresizingMaskIntoConstraints = NO;
            
            control.backgroundColor = nil;
            
            control;
        });
        [self.contentView addSubview:self.sortControl];
        
        NSDictionary *views = @{
                                @"rank": self.rank,
                                @"userIcon": self.userIcon,
                                @"username": self.username,
                                @"observationCount": self.observationCount,
                                @"speciesCount": self.speciesCount,
                                @"sortControl": self.sortControl,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[rank(==35)]-10-[userIcon(==50)]-15-[username]-20-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[rank(==35)]-10-[userIcon(==50)]-15-[observationCount]-20-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[rank(==35)]-10-[userIcon(==50)]-15-[speciesCount]-20-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[rank(==35)]-10-[userIcon(==50)]-15-[sortControl]-20-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[rank(==30)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[userIcon(==50)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[username(==20)]-1-[observationCount]-1-[speciesCount]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[username(==20)]-3-[sortControl]-5-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

        
    }
    
    return self;
}

- (void)prepareForReuse {
    self.userIcon.image = nil;
    [self.userIcon cancelImageRequestOperation];
    
    self.username.text = nil;
    self.observationCount.text = nil;
    self.speciesCount.text = nil;
}

@end
