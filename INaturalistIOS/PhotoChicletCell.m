//
//  PhotoChicletView.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/22/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "PhotoChicletCell.h"

@implementation PhotoChicletCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.photoImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.contentMode = UIViewContentModeScaleAspectFill;
            iv.clipsToBounds = YES;

            iv;
        });
        [self.contentView addSubview:self.photoImageView];
        
        self.deleteButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;

            button.layer.cornerRadius = 11;
            FAKIcon *close = [FAKIonIcons closeIconWithSize:10];
            [button setAttributedTitle:close.attributedString forState:UIControlStateNormal];
            button.tintColor = [UIColor whiteColor];
            button.backgroundColor = [UIColor grayColor];

            button;
        });
        [self.contentView addSubview:self.deleteButton];
        
        self.defaultButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;
            
            button.tintColor = [UIColor grayColor];
            button.titleLabel.textColor = [UIColor grayColor];
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            
            button.backgroundColor = [UIColor whiteColor];
            
            button;
        });
        [self.contentView addSubview:self.defaultButton];
        
        NSDictionary *views = @{
                                @"photo": self.photoImageView,
                                @"delete": self.deleteButton,
                                @"default": self.defaultButton,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-9-[photo]-9-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-9-[default]-9-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-9-[photo(==71)]-11-[default]-11-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        //
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.deleteButton
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0
                                                          constant:22.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.deleteButton
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0
                                                          constant:22.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.deleteButton
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.photoImageView
                                                        attribute:NSLayoutAttributeTrailing
                                                       multiplier:1.0f
                                                          constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.deleteButton
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.photoImageView
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0f
                                                          constant:4.0f]];



    }
    
    return self;
}

@end
