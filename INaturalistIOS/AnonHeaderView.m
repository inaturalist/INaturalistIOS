//
//  AnonHeaderView.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/11/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "AnonHeaderView.h"
#import "UIColor+INaturalist.h"

@interface AnonHeaderView ()
@property UILabel *anonPrompt;
@property UIView *container;
@end

@implementation AnonHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor inatTint];
        
        self.container = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            
            self.anonPrompt = ({
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
                label.translatesAutoresizingMaskIntoConstraints = NO;
                
                label.font = [UIFont systemFontOfSize:15];
                label.textColor = [UIColor whiteColor];
                label.numberOfLines = 0;
                label.textAlignment = NSTextAlignmentCenter;

                label.text = NSLocalizedString(@"Share your observations with the community.",
                                               @"Prompt to sign in on the Me tab header.");
                
                [label setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
                
                label;
            });
            [view addSubview:self.anonPrompt];
            
            self.loginButton = ({
                UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
                button.translatesAutoresizingMaskIntoConstraints = NO;
                
                button.tintColor = [UIColor inatTint];
                button.backgroundColor = [UIColor whiteColor];
                button.titleLabel.font = [UIFont boldSystemFontOfSize:button.titleLabel.font.pointSize];
                
                button.layer.cornerRadius = 17.0f;

                [button setTitle:NSLocalizedString(@"Log In", @"Title for button that allows users to log in to their existing iNat account")
                        forState:UIControlStateNormal];
                
                button;
            });
            [view addSubview:self.loginButton];

            self.signupButton = ({
                UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
                button.translatesAutoresizingMaskIntoConstraints = NO;
                
                button.tintColor = [UIColor inatTint];
                button.backgroundColor = [UIColor whiteColor];
                button.titleLabel.font = [UIFont boldSystemFontOfSize:button.titleLabel.font.pointSize];
                
                button.layer.cornerRadius = 17.0f;
                
                [button setTitle:NSLocalizedString(@"Sign Up", @"Title for button that allows users to sign up for a new iNat account")
                        forState:UIControlStateNormal];
                
                button;
            });
            [view addSubview:self.signupButton];
            
            view;
        });
        [self addSubview:self.container];
        
        
        
        NSDictionary *views = @{
                                @"container": self.container,
                                @"prompt": self.anonPrompt,
                                @"login": self.loginButton,
                                @"signup": self.signupButton,
                                };
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.container
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:0.7f
                                                          constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.container
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeHeight
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.container
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0f
                                                          constant:1.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.container
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:1.0f]];
        
        [self.container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[prompt]-|"
                                                                              options:0
                                                                              metrics:0
                                                                                views:views]];
        
        [self.container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[signup]-18-[login(==signup)]-|"
                                                                              options:0
                                                                              metrics:0
                                                                                views:views]];
        [self.container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[prompt]-[signup(==36)]-12-|"
                                                                               options:0
                                                                               metrics:0
                                                                                 views:views]];
        [self.container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[prompt]-[login(==36)]-12-|"
                                                                               options:0
                                                                               metrics:0
                                                                                 views:views]];

        
    }
    
    return self;
}

@end
