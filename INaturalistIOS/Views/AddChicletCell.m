//
//  AddChicletCell.m
//  
//
//  Created by Alex Shepard on 10/22/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//


#import <FontAwesomeKit/FAKIonIcons.h>

#import "AddChicletCell.h"

@implementation AddChicletCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        UILabel *plusLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.layer.borderColor = [UIColor grayColor].CGColor;
            label.layer.borderWidth = 1.0f;
            label.tintColor = [UIColor grayColor];
            FAKIcon *plus = [FAKIonIcons iosPlusEmptyIconWithSize:25];
            label.attributedText = plus.attributedString;
            label.textAlignment = NSTextAlignmentCenter;
            
            label;
        });
        [self.self.contentView addSubview:plusLabel];
        
        NSDictionary *views = @{ @"plus": plusLabel };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-9-[plus]-9-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-9-[plus]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:plusLabel
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:plusLabel
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0f
                                                          constant:0.0f]];
    }
    

    return self;
}

@end
