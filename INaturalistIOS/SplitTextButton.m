//
//  SplitTextButton.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/21/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "SplitTextButton.h"

@interface SplitTextButton ()
@property NSLayoutConstraint *leadingTitleWidthConstraint;
@end

@implementation SplitTextButton

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1f];
        self.tintColor = [UIColor whiteColor];
        self.layer.cornerRadius = 2.0f;
        
        self.leadingTitleLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor whiteColor];
            label.highlightedTextColor = [UIColor grayColor];
            label.textAlignment = NSTextAlignmentCenter;
            
            label;
        });
        [self addSubview:self.leadingTitleLabel];
        
        self.separator = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            
            view.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2f];
            
            view;
        });
        [self addSubview:self.separator];
        
        self.trailingTitleLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor whiteColor];
            label.highlightedTextColor = [UIColor grayColor];
            
            label;
        });
        [self addSubview:self.trailingTitleLabel];
        
        NSDictionary *views = @{
                                @"left": self.leadingTitleLabel,
                                @"separator": self.separator,
                                @"right": self.trailingTitleLabel,
                                };
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[left]-0-[separator]-0-[right]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[left]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[separator]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[right]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        self.leadingTitleWidthConstraint = [NSLayoutConstraint constraintWithItem:self.leadingTitleLabel
                                                                        attribute:NSLayoutAttributeWidth
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0f
                                                                         constant:40];  // default width
        [self addConstraint:self.leadingTitleWidthConstraint];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.separator
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0f
                                                          constant:0.5f]];
    }
    
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    [UIView animateWithDuration:0.1f
                     animations:^{
                         self.leadingTitleLabel.highlighted = highlighted;
                         self.trailingTitleLabel.highlighted = highlighted;
                     }];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
}

- (CGFloat)leadingTitleWidth {
    return self.leadingTitleWidthConstraint.constant;
}

- (void)setLeadingTitleWidth:(CGFloat)width {
    self.leadingTitleWidthConstraint.constant = width;
    [self setNeedsUpdateConstraints];
}

@end
