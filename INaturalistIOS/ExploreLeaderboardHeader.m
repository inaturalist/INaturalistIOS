//
//  ExploreLeaderboardHeader.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/19/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "ExploreLeaderboardHeader.h"

@implementation ExploreLeaderboardHeader

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
            UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            visualEffectView.frame = self.bounds;
            visualEffectView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            [self addSubview:visualEffectView];
        } else {
            self.backgroundColor = [UIColor whiteColor];
        }
        
        self.title = [[UILabel alloc] initWithFrame:CGRectZero];
        self.title.translatesAutoresizingMaskIntoConstraints = NO;
        self.title.textAlignment = NSTextAlignmentCenter;
        self.title.textColor = [UIColor darkGrayColor];
        self.title.font = [UIFont boldSystemFontOfSize:16.0f];
        [self addSubview:self.title];
        
        UILabel *spanLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        spanLabel.translatesAutoresizingMaskIntoConstraints = NO;
        spanLabel.textAlignment = NSTextAlignmentCenter;
        spanLabel.text = NSLocalizedString(@"Time Period", @"Label for the time period selector in the explore leaderboard header.");
        spanLabel.textColor = [UIColor grayColor];
        spanLabel.font = [UIFont systemFontOfSize:12.0f];
        [self addSubview:spanLabel];
        
        UILabel *sortLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        sortLabel.translatesAutoresizingMaskIntoConstraints = NO;
        sortLabel.textAlignment = NSTextAlignmentCenter;
        sortLabel.text = NSLocalizedString(@"Sort", @"Label for the sort selector in the explore leaderboard header.");
        sortLabel.textColor = [UIColor grayColor];
        sortLabel.font = [UIFont systemFontOfSize:12.0f];
        [self addSubview:sortLabel];
        
        NSDate *date = [NSDate date];
        
        NSDateFormatter *monthFormatter = [[NSDateFormatter alloc] init];
        monthFormatter.dateFormat = @"MMM";
        NSString *month = [monthFormatter stringFromDate:date];
        
        NSDateFormatter *yearFormatter = [[NSDateFormatter alloc] init];
        yearFormatter.dateFormat = @"yyyy";
        NSString *year = [yearFormatter stringFromDate:date];
        
        self.spanSelector = [[UISegmentedControl alloc] initWithItems:@[month, year]];
        self.spanSelector.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.spanSelector];
        
        self.sortSelector = [[UISegmentedControl alloc] initWithItems:@[@"Obs", @"Species"]];
        self.sortSelector.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.sortSelector];
        
        UIView *bottomEdge = [[UIView alloc] initWithFrame:CGRectZero];
        bottomEdge.translatesAutoresizingMaskIntoConstraints = NO;
        bottomEdge.backgroundColor = [UIColor grayColor];
        [self addSubview:bottomEdge];
        
        NSDictionary *views = @{
                                @"title": self.title,
                                @"spanLabel": spanLabel,
                                @"sortLabel": sortLabel,
                                @"span": self.spanSelector,
                                @"sort": self.sortSelector,
                                @"bottomEdge": bottomEdge,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[title]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[spanLabel]-[sortLabel(==spanLabel)]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[span]-[sort(==span)]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[bottomEdge]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[title]-[spanLabel]-[span]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[title]-[sortLabel]-[sort]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomEdge(==0.5)]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        self.clipsToBounds = NO;
        
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0.0f, 0.5f);
        self.layer.shadowOpacity = 0.5f;
        self.layer.shadowRadius = 1.5f;
        
    }
    
    return self;
}

@end
