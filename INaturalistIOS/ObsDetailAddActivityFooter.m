//
//  ObsDetailAddActivityFooter.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/10/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "ObsDetailAddActivityFooter.h"
#import "UIColor+INaturalist.h"

@implementation ObsDetailAddActivityFooter

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        
        self.commentButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            button.backgroundColor = [UIColor inatTint];
            button.layer.cornerRadius = 20.0f;
            button.clipsToBounds = YES;
            button.tintColor = [UIColor whiteColor];
            button.titleLabel.font = [UIFont boldSystemFontOfSize:17.0f];

            [button setTitle:NSLocalizedString(@"Comment", nil)
                    forState:UIControlStateNormal];
            
            button;
        });
        [self addSubview:self.commentButton];
        
        self.suggestIDButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            button.backgroundColor = [UIColor inatTint];
            button.layer.cornerRadius = 20.0f;
            button.clipsToBounds = YES;
            button.tintColor = [UIColor whiteColor];
            button.titleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
            
            [button setTitle:NSLocalizedString(@"Suggest ID", nil)
                    forState:UIControlStateNormal];
            
            button;
        });
        [self addSubview:self.suggestIDButton];

        NSDictionary *views = @{
                                @"comment": self.commentButton,
                                @"suggestID": self.suggestIDButton,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-15-[comment]-15-[suggestID(==comment)]-15-|"
                                                                    options:0
                                                                    metrics:0
                                                                       views:views]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.commentButton
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0f
                                                          constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.suggestIDButton
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.commentButton
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0f
                                                          constant:40.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.suggestIDButton
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0f
                                                          constant:40.0f]];
        
        
        
        
    }
    
    return self;
}

- (void)prepareForReuse {
    [self.commentButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
    [self.suggestIDButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
}

@end
