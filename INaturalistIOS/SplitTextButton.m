//
//  SplitTextButton.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/21/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "SplitTextButton.h"

@interface SplitTextButton ()
@property UIView *separator;
@end

@implementation SplitTextButton

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1f];
        self.tintColor = [UIColor whiteColor];
        self.layer.cornerRadius = 2.0f;
        
        self.leftTitleLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor whiteColor];
            label.highlightedTextColor = [UIColor grayColor];
            label.textAlignment = NSTextAlignmentCenter;
            
            label;
        });
        [self addSubview:self.leftTitleLabel];
        
        self.separator = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            
            view.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2f];
            
            view;
        });
        [self addSubview:self.separator];
        
        self.rightTitleLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor whiteColor];
            label.highlightedTextColor = [UIColor grayColor];
            
            label;
        });
        [self addSubview:self.rightTitleLabel];
        
        NSDictionary *views = @{
                                @"left": self.leftTitleLabel,
                                @"separator": self.separator,
                                @"right": self.rightTitleLabel,
                                };
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[left]-0-[separator]-20-[right]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[left]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[separator]-2-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[right]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.leftTitleLabel
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:0.18f
                                                          constant:0.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.separator
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0f
                                                          constant:1.0f]];
    }
    
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    [UIView animateWithDuration:0.1f
                     animations:^{
                         self.leftTitleLabel.highlighted = highlighted;
                         self.rightTitleLabel.highlighted = highlighted;
                     }];
    
    NSLog(@"highlighted is %d", highlighted);
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    NSLog(@"selected is %d", selected);
}

@end
