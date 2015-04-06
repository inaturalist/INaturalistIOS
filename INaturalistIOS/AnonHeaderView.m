//
//  AnonHeaderView.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/11/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "AnonHeaderView.h"

@interface AnonHeaderView ()
@property UILabel *noIconLabel;
@end

@implementation AnonHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor whiteColor];
        
        self.noIconLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.layer.borderColor = [UIColor lightGrayColor].CGColor;
            label.layer.borderWidth = 2.0f;
            label.layer.cornerRadius = 40;      // circular with an 80x80 frame
            
            label.text = @"?";
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont boldSystemFontOfSize:66.0f];
            label.textColor = [UIColor lightGrayColor];
            
            label.clipsToBounds = YES;
            
            label;
        });
        [self addSubview:self.noIconLabel];
        
        self.loginButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            button.tintColor = [UIColor grayColor];
            
            button;
        });
        [self addSubview:self.loginButton];
        
        self.signupButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            button.layer.cornerRadius = 15.0f;
            button.clipsToBounds = YES;
            button.backgroundColor = [UIColor grayColor];
            button.tintColor = [UIColor whiteColor];
            button.titleLabel.font = [UIFont boldSystemFontOfSize:self.loginButton.titleLabel.font.pointSize];
            
            button.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 20);

            button;
        });
        [self addSubview:self.signupButton];

        UIView *bottomEdge = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            
            view.backgroundColor = [UIColor lightGrayColor];
            
            view;
        });
        [self addSubview:bottomEdge];
        
        NSDictionary *views = @{
                                @"noIcon": self.noIconLabel,
                                @"login": self.loginButton,
                                @"signup": self.signupButton,
                                @"bottomEdge": bottomEdge
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-20-[noIcon(==80)]-15-[login]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-20-[noIcon(==80)]-15-[signup]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[bottomEdge]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[signup(==30)]-20-[login]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomEdge(==0.5)]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.noIconLabel
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.noIconLabel
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
