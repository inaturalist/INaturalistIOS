//
//  RestrictedListHeader.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/1/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "RestrictedListHeader.h"
#import "UIColor+ExploreColors.h"

@implementation RestrictedListHeader

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        
        self.contentView.backgroundColor = [UIColor colorWithHexString:@"#f0f0f0"];
        
        self.titleLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            // use autolayout
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.font = [UIFont systemFontOfSize:12.0f];
            label.backgroundColor = [UIColor clearColor];
            label.textColor = [UIColor blackColor];
            label;
        });
        [self.contentView addSubview:self.titleLabel];
        
        self.clearButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            
            FAKIcon *clear = [FAKIonIcons iosCloseEmptyIconWithSize:30.0f];
            [clear addAttribute:NSForegroundColorAttributeName value:[UIColor inatGreen]];
            [button setAttributedTitle:clear.attributedString forState:UIControlStateNormal];
            
            button.frame = CGRectZero;
            // use autolayout
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            button;
        });
        [self.contentView addSubview:self.clearButton];
        
        NSDictionary *views = @{
                                @"titleLabel": self.titleLabel,
                                @"clearButton": self.clearButton,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-15-[titleLabel]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[clearButton(==30)]-15-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleLabel]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[clearButton]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
    }
    
    return self;
}

@end
