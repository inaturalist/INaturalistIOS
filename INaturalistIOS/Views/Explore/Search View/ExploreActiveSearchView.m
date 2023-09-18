//
//  ExploreActiveSearchView.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/5/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreActiveSearchView.h"
#import "UIColor+ExploreColors.h"
#import "INaturalist-Swift.h"

@interface ExploreActiveSearchView () {
    UIView *activeSearchTextContainerView;
    
}
@end

@implementation ExploreActiveSearchView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor clearColor];

        activeSearchTextContainerView = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            view.backgroundColor = [UIColor inatGray];
            
            self.activeSearchLabel = ({
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
                label.translatesAutoresizingMaskIntoConstraints = NO;
                label.textAlignment = NSTextAlignmentNatural;
                label.font = [UIFont systemFontOfSize:11.0f];
                label.numberOfLines = 0;
                label.textColor = [UIColor whiteColor];
                label;
            });
            [view addSubview:self.activeSearchLabel];

            self.removeActiveSearchButton = ({
                UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];

                [button setImage:[UIImage iconImageWithSystemName:@"xmark" size:IconImageSizeSmall]
                        forState:UIControlStateNormal];
                button.tintColor = [UIColor whiteColor];

                button.translatesAutoresizingMaskIntoConstraints = NO;
                button.frame = CGRectZero;
                button.accessibilityLabel = NSLocalizedString(@"Remove active search filters", nil);
                
                button;
            });
            [view addSubview:self.removeActiveSearchButton];

            view;
        });
        
        [self addSubview:activeSearchTextContainerView];

        NSDictionary *views = @{
                                @"activeSearchTextContainerView": activeSearchTextContainerView,
                                @"activeSearchLabel": self.activeSearchLabel,
                                @"removeActiveSearchButton": self.removeActiveSearchButton,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[activeSearchTextContainerView]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[activeSearchTextContainerView(==50)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[activeSearchLabel]-[removeActiveSearchButton]-15-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        // pin the search label to the screen width - 75 px, to leave room to accomodate
        // the close button & padding
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activeSearchLabel
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0f
                                                          constant:-75]];
        
        // vertically center the search label and the close button in the container
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activeSearchLabel
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:activeSearchTextContainerView
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        // vertically center the search label and the close button in the container
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.removeActiveSearchButton
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:activeSearchTextContainerView
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0.0f]];

    }
    
    return self;
}

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    if (!self.hidden && CGRectContainsPoint(self.removeActiveSearchButton.frame, point))
        return self.removeActiveSearchButton;
    
    return nil;
}


@end
