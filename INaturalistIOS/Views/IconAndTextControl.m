//
//  IconAndTextControl.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/28/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "IconAndTextControl.h"

@interface IconAndTextControl ()

@property UILabel *iconLabel;
@property UILabel *textLabel;
@property UIView *separator;

@end

@implementation IconAndTextControl

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.iconLabel = ({
            UILabel *label = [UILabel new];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.textAlignment = NSTextAlignmentCenter;
            
            label;
        });
        [self addSubview:self.iconLabel];
        
        self.textLabel = ({
            UILabel *label = [UILabel new];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.textAlignment = NSTextAlignmentNatural;
            label.font = [UIFont systemFontOfSize:13];
            
            label;
        });
        [self addSubview:self.textLabel];
        
        
        self.separator = ({
            UIView *view = [UIView new];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            
            view;
        });
        [self addSubview:self.separator];
        
        NSDictionary *views = @{
                                @"icon": self.iconLabel,
                                @"text": self.textLabel,
                                @"separator": self.separator,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[icon(==33)][separator(==1)]-7-[text]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[icon]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[separator]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[text]|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    
    return self;
}

- (void)setAttributedIconTitle:(NSAttributedString *)attrTitle {
    self.iconLabel.attributedText = attrTitle;
}

- (NSAttributedString *)attributedIconTitle {
    return self.iconLabel.attributedText;
}

- (void)setTextTitle:(NSString *)title {
    self.textLabel.text = title;
}

- (NSString *)textTitle {
    return self.textLabel.text;
}

- (void)setTextColor:(UIColor *)textColor {
    self.textLabel.textColor = textColor;
}

- (UIColor *)textColor {
    return self.textLabel.textColor;
}

- (void)setSeparatorColor:(UIColor *)color {
    self.separator.backgroundColor = color;
}

- (UIColor *)separatorColor {
    return self.separator.backgroundColor;
}

@end
