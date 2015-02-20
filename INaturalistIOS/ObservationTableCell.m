//
//  ObservationTableCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/19/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "ObservationTableCell.h"

@implementation ObservationTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.obsImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.contentMode = UIViewContentModeScaleAspectFit;
            
            iv;
        });
        [self addSubview:self.obsImageView];
        
        self.title = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor blackColor];
            label.font = [UIFont boldSystemFontOfSize:17.0f];
            
            label;
        });
        [self addSubview:self.title];
        
        self.subtitle = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor lightGrayColor];
            label.font = [UIFont systemFontOfSize:14.0f];
            
            label;
        });
        [self addSubview:self.subtitle];
        
        self.upperRight = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor lightGrayColor];
            label.font = [UIFont systemFontOfSize:10.0f];
                        
            label;
        });
        [self addSubview:self.upperRight];
        
        self.syncImage = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.image = [UIImage imageNamed:@"01-refresh.png"];
            
            iv;
        });
        [self addSubview:self.syncImage];
        
        self.activityButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.frame = CGRectZero;
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            button.tintColor = [UIColor whiteColor];
            button.titleLabel.font = [UIFont systemFontOfSize:11.0f];
            [button setBackgroundImage:[UIImage imageNamed:@"08-chat-red.png"] forState:UIControlStateNormal];
            
            button;
        });
        [self addSubview:self.activityButton];
        
        self.interactiveActivityButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.frame = CGRectZero;
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            button;
        });
        [self addSubview:self.interactiveActivityButton];
        
        NSDictionary *views = @{
                                @"iv": self.obsImageView,
                                @"title": self.title,
                                @"subtitle": self.subtitle,
                                @"upperRight": self.upperRight,
                                @"syncImage": self.syncImage,
                                @"activityButton": self.activityButton,
                                @"interactiveActivityButton": self.interactiveActivityButton,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-5-[iv(==44)]-[title]-[upperRight(==43)]-5-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-5-[iv(==44)]-[subtitle]-[syncImage(==16)]-[activityButton(==24)]-5-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[iv(==44)]-5-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[title(==21)]-2-[subtitle(==21)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[upperRight(==15)]-8-[syncImage(==16)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[upperRight(==15)]-8-[activityButton(==22)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

    }
    
    return self;
}

@end

