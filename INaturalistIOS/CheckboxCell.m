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
        
        self.checkButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            button.titleLabel.textAlignment = NSTextAlignmentCenter;
            button.tintColor = self.tintColor;
            
            [button addTarget:self action:@selector(toggleSelected) forControlEvents:UIControlEventTouchUpInside];
            
            button;
        });
        [self.contentView addSubview:self.checkButton];
        
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
                                @"icon": self.checkButton,
                                @"text": self.checkText,
                                };
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[icon]-0-[text]-|"
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
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.checkButton
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
    
    [self.checkButton setAttributedTitle:(selected ? checkSelected : checkDeselected).attributedString
                                forState:UIControlStateNormal];
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    
    self.checkButton.tintColor = tintColor;
    self.checkText.textColor = tintColor;
}

- (void)toggleSelected {
    [self setSelected:!self.selected animated:YES];
}



@end
