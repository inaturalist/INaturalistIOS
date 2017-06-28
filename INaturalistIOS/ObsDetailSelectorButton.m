//
//  ObsDetailSelectorButton.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/10/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ObsDetailSelectorButton.h"
#import "UIColor+INaturalist.h"

@interface ObsDetailSelectorButton () {
    NSInteger _count;
}

@property UIView *underline;
@property UILabel *countLabel;
@property UILabel *iconLabel;
@property NSAttributedString *enabledIcon;
@property NSAttributedString *disabledIcon;
@end

@implementation ObsDetailSelectorButton


+ (instancetype)buttonWithSelectorType:(ObsDetailSelectorButtonType)type {
    ObsDetailSelectorButton *button = [ObsDetailSelectorButton buttonWithType:UIButtonTypeSystem];
    if (!button) {
        return nil;
    }
    
    if (type == ObsDetailSelectorButtonTypeInfo) {
        
        FAKIcon *info = [FAKIonIcons iosInformationIconWithSize:30];
        [info addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor]];
        button.enabledIcon = info.attributedString;
        [info addAttribute:NSForegroundColorAttributeName value:[UIColor inatTint]];
        button.disabledIcon = info.attributedString;
        
        [button.iconLabel setAttributedText:info.attributedString];
    } else if (type == ObsDetailSelectorButtonTypeActivity) {
        
        FAKIcon *chat = [FAKIonIcons chatbubbleWorkingIconWithSize:30];
        [chat addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor]];
        button.enabledIcon = chat.attributedString;
        [chat addAttribute:NSForegroundColorAttributeName value:[UIColor inatTint]];
        button.disabledIcon = chat.attributedString;
        
    } else if (type == ObsDetailSelectorButtonTypeFaves) {
        
        FAKIcon *star = [FAKIonIcons iosStarIconWithSize:30];
        [star addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor]];
        button.enabledIcon = star.attributedString;
        [star addAttribute:NSForegroundColorAttributeName value:[UIColor inatTint]];
        button.disabledIcon = star.attributedString;
        
    }
    
    button.underline = ({
        UIView *view = [UIView new];
        view.translatesAutoresizingMaskIntoConstraints = NO;

        view.backgroundColor = [UIColor inatTint];
        view.hidden = YES;
        
        view;
    });
    [button addSubview:button.underline];
    
    button.countLabel = ({
        UILabel *label = [UILabel new];
        label.translatesAutoresizingMaskIntoConstraints = NO;
                
        label;
    });
    [button addSubview:button.countLabel];
    
    button.iconLabel = ({
        UILabel *label = [UILabel new];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        
        label.attributedText = button.enabledIcon;

        label;
    });
    [button addSubview:button.iconLabel];

    
    NSDictionary *views = @{
                            @"underline": button.underline,
                            @"count": button.countLabel,
                            @"icon": button.iconLabel,
                            };
    
    [button addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[icon]-[count]"
                                                                   options:0
                                                                   metrics:0
                                                                     views:views]];
    
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button.iconLabel
                                                       attribute:NSLayoutAttributeCenterX
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:button
                                                       attribute:NSLayoutAttributeCenterX
                                                      multiplier:1.0f
                                                        constant:0.0f]];

    [button addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[icon]-12-|"
                                                                   options:0
                                                                   metrics:0
                                                                     views:views]];
    [button addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[count]-12-|"
                                                                   options:0
                                                                   metrics:0
                                                                     views:views]];

    [button addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[underline]-|"
                                                                  options:0
                                                                  metrics:0
                                                                     views:views]];
    [button addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[underline(==3)]-0-|"
                                                                   options:0
                                                                   metrics:0
                                                                     views:views]];

    
    return button;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    
    if (enabled) {
        self.iconLabel.attributedText = self.enabledIcon;
        self.underline.hidden = YES;
        self.countLabel.textColor = [UIColor colorWithHexString:@"#8e8e93"];
    } else {
        self.iconLabel.attributedText = self.disabledIcon;
        self.underline.hidden = NO;
        self.countLabel.textColor = [UIColor inatTint];
    }
}

- (NSInteger)count {
    return _count;
}

- (void)setCount:(NSInteger)count {
    _count = count;
    
    if (count > 0) {
        self.countLabel.text = @"*";
    } else {
        self.countLabel.text = nil;
    }
}

@end
