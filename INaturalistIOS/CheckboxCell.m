//
//  CheckboxCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/25/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "CheckboxCell.h"


@interface CheckboxCell () {
    FAKIcon *checkSelected;
    FAKIcon *checkDeselected;
}
@end

@implementation CheckboxCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
                
        checkSelected = [FAKIonIcons iosCheckmarkIconWithSize:30.0f];
        checkDeselected = [FAKIonIcons iosCheckmarkOutlineIconWithSize:30.0f];
        
        self.checkIcon = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = self.tintColor;
            
            label;
        });
        [self.contentView addSubview:self.checkIcon];
        
        self.checkText = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.numberOfLines = 2;
            label.font = [UIFont systemFontOfSize:13.0f];
            label.textColor = self.tintColor;
            
            label;
        });
        [self.contentView addSubview:self.checkText];
        
        NSDictionary *views = @{
                                @"icon": self.checkIcon,
                                @"text": self.checkText,
                                };
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[icon(==60)]-0-[text]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[icon]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[text]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.checkIcon
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:0.18f
                                                          constant:0.0f]];
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    self.checkIcon.attributedText = (selected ? checkSelected : checkDeselected).attributedString;
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    
    self.checkIcon.textColor = tintColor;
    self.checkText.textColor = tintColor;
}

@end
