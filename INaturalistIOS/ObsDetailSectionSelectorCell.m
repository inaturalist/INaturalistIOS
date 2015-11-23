//
//  ObsDetailSectionSelectorCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "ObsDetailSectionSelectorCell.h"
#import "UIColor+INaturalist.h"

@implementation ObsDetailSectionSelectorCell

- (void)awakeFromNib {
    
    self.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.1f];
    
    FAKIcon *info = [FAKIonIcons iosInformationIconWithSize:24];
    [info addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor]];
    [self.infoButton setAttributedTitle:info.attributedString forState:UIControlStateNormal];
    [info addAttribute:NSForegroundColorAttributeName value:[UIColor inatTint]];
    [self.infoButton setAttributedTitle:info.attributedString forState:UIControlStateDisabled];
    
    
    FAKIcon *chat = [FAKIonIcons chatbubbleWorkingIconWithSize:24];
    [chat addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor]];
    [self.activityButton setAttributedTitle:chat.attributedString forState:UIControlStateNormal];
    [chat addAttribute:NSForegroundColorAttributeName value:[UIColor inatTint]];
    [self.activityButton setAttributedTitle:chat.attributedString forState:UIControlStateDisabled];
    
    
    FAKIcon *star = [FAKIonIcons iosStarIconWithSize:24];
    [star addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor]];
    [self.favesButton setAttributedTitle:star.attributedString forState:UIControlStateNormal];
    [star addAttribute:NSForegroundColorAttributeName value:[UIColor inatTint]];
    [self.favesButton setAttributedTitle:star.attributedString forState:UIControlStateDisabled];
}

- (void)prepareForReuse {
    self.infoButton.enabled = YES;
    self.activityButton.enabled = YES;
    self.favesButton.enabled = YES;
}

@end
